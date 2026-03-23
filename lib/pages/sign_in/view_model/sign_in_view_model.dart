import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'package:collection/collection.dart';
import 'package:matrix/matrix_api_lite/utils/logs.dart';

import 'package:afterdamage/config/app_config.dart';
import 'package:afterdamage/config/setting_keys.dart';
import 'package:afterdamage/pages/sign_in/view_model/flows/sort_homeservers.dart';
import 'package:afterdamage/pages/sign_in/view_model/model/public_homeserver_data.dart';
import 'package:afterdamage/pages/sign_in/view_model/sign_in_state.dart';
import 'package:afterdamage/widgets/matrix.dart';

class SignInViewModel extends ValueNotifier<SignInState> {
  final MatrixState matrixService;
  final bool signUp;
  final TextEditingController filterTextController = TextEditingController();

  SignInViewModel(this.matrixService, {required this.signUp})
    : super(SignInState()) {
    refreshPublicHomeservers();
    filterTextController.addListener(_filterHomeservers);
  }

  @override
  void dispose() {
    filterTextController.removeListener(_filterHomeservers);
    super.dispose();
  }

  void _filterHomeservers() {
    final filterText = filterTextController.text.trim().toLowerCase();
    final filteredPublicHomeservers =
        value.publicHomeservers.data
            ?.where(
              (homeserver) =>
                  (homeserver.name?.toLowerCase().contains(filterText) ?? false) ||
                  (homeserver.description?.toLowerCase().contains(filterText) ?? false),
            )
            .toList() ??
        [];
    // If the user typed a domain-like string not in the list, add it as a custom entry
    final splitted = filterText.split('.');
    if (splitted.length >= 2 && !splitted.any((part) => part.isEmpty)) {
      if (!filteredPublicHomeservers.any(
        (homeserver) => homeserver.name == filterText,
      )) {
        filteredPublicHomeservers.add(
          PublicHomeserverData(
            name: filterText,
            description: 'Custom homeserver',
          ),
        );
      }
    }
    value = value.copyWith(
      filteredPublicHomeservers: filteredPublicHomeservers,
    );
  }

  void refreshPublicHomeservers() async {
    value = value.copyWith(publicHomeservers: AsyncSnapshot.waiting());
    final defaultHomeserverData = PublicHomeserverData(
      name: AppSettings.defaultHomeserver.value,
    );
    try {
      final client = await matrixService.getLoginClient();
      final response = await client.httpClient.get(AppConfig.homeserverList);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final homeserverJsonList = json['public_servers'] as List;

      final publicHomeservers = homeserverJsonList
          .map((json) => PublicHomeserverData.fromJson(json))
          .toList();

      if (signUp) {
        publicHomeservers.removeWhere((server) {
          return server.regMethod == null;
        });
      }

      publicHomeservers.sort(sortHomeservers);

      final defaultServer =
          publicHomeservers.singleWhereOrNull(
            (server) => server.name == AppSettings.defaultHomeserver.value,
          ) ??
          defaultHomeserverData;

      publicHomeservers.insert(0, defaultServer);

      // Merge curated servers that aren't already in the remote list
      for (final hs in AppConfig.knownHomeservers) {
        final hsName = hs['name'];
        if (hsName != null &&
            !publicHomeservers.any((s) => s.name == hsName)) {
          publicHomeservers.add(PublicHomeserverData(
            name: hsName,
            description: hs['description'],
          ));
        }
      }

      value = value.copyWith(
        selectedHomeserver: value.selectedHomeserver ?? publicHomeservers.first,
        publicHomeservers: AsyncSnapshot.withData(
          ConnectionState.done,
          publicHomeservers,
        ),
      );
    } catch (e, s) {
      Logs().w('Unable to fetch public homeservers, using curated list...', e, s);
      // Fall back to curated known homeservers
      final fallbackServers = AppConfig.knownHomeservers
          .map((hs) => PublicHomeserverData(
                name: hs['name'],
                description: hs['description'],
              ))
          .toList();
      final defaultServer = fallbackServers.firstWhereOrNull(
            (server) => server.name == AppSettings.defaultHomeserver.value,
          ) ??
          defaultHomeserverData;
      // Ensure default is at the top
      fallbackServers.removeWhere((s) => s.name == defaultServer.name);
      fallbackServers.insert(0, defaultServer);
      value = value.copyWith(
        selectedHomeserver: defaultServer,
        publicHomeservers: AsyncSnapshot.withData(
          ConnectionState.done,
          fallbackServers,
        ),
      );
    }
    _filterHomeservers();
  }

  void selectHomeserver(PublicHomeserverData? publicHomeserverData) {
    value = value.copyWith(selectedHomeserver: publicHomeserverData);
  }

  void setLoginLoading(AsyncSnapshot<bool> loginLoading) {
    value = value.copyWith(loginLoading: loginLoading);
  }
}
