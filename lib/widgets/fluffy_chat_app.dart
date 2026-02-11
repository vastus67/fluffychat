import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:afterdamage/config/routes.dart';
import 'package:afterdamage/config/setting_keys.dart';
import 'package:afterdamage/config/themes.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/theme/dracula_accents.dart';
import 'package:afterdamage/widgets/app_lock.dart';
import 'package:afterdamage/widgets/theme_builder.dart';
import '../utils/custom_scroll_behaviour.dart';
import 'matrix.dart';

class FluffyChatApp extends StatelessWidget {
  final Widget? testWidget;
  final List<Client> clients;
  final String? pincode;
  final SharedPreferences store;

  const FluffyChatApp({
    super.key,
    this.testWidget,
    required this.clients,
    required this.store,
    this.pincode,
  });

  /// getInitialLink may rereturn the value multiple times if this view is
  /// opened multiple times for example if the user logs out after they logged
  /// in with qr code or magic link.
  static bool gotInitialLink = false;

  // Router must be outside of build method so that hot reload does not reset
  // the current path.
  static final GoRouter router = GoRouter(
    routes: AppRoutes.routes,
    debugLogDiagnostics: true,
  );

  @override
  Widget build(BuildContext context) {
    return ThemeBuilder(
      builder: (context, themeMode, primaryColor) {
        // Get the current Dracula accent from settings
        final accentName = AppSettings.draculaAccent.value;
        final draculaAccent = DraculaAccent.values.firstWhere(
          (accent) => accent.name == accentName,
          orElse: () => DraculaAccent.red,  // Default to red accent
        );

        return MaterialApp.router(
          title: AppSettings.applicationName.value,
          themeMode: themeMode,
          // Use light theme for light mode
          theme: FluffyThemes.buildTheme(
            context,
            Brightness.light,
            primaryColor,
          ),
          // Use Dracula accent theme for dark mode
          darkTheme: FluffyThemes.buildAccentTheme(
            context,
            draculaAccent,
          ),
          scrollBehavior: CustomScrollBehavior(),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          routerConfig: router,
          builder: (context, child) => AppLockWidget(
            pincode: pincode,
            clients: clients,
            // Need a navigator above the Matrix widget for
            // displaying dialogs
            child: Matrix(
              clients: clients,
              store: store,
              child: testWidget ?? child,
            ),
          ),
        );
      },
    );
  }
}
