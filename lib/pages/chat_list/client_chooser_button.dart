import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'package:afterdamage/widgets/avatar.dart';
import 'package:afterdamage/widgets/matrix.dart';

/// Avatar button that opens the navigation drawer
/// All previous menu options have been moved to the main app drawer
class ClientChooserButton extends StatelessWidget {
  final dynamic controller;

  const ClientChooserButton(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final matrix = Matrix.of(context);

    return FutureBuilder<Profile>(
      future: matrix.client.isLogged() ? matrix.client.fetchOwnProfile() : null,
      builder: (context, snapshot) => Material(
        clipBehavior: Clip.hardEdge,
        borderRadius: BorderRadius.circular(6),
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Open the main navigation drawer
            Scaffold.of(context).openDrawer();
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Avatar(
              mxContent: snapshot.data?.avatarUrl,
              name:
                  snapshot.data?.displayName ?? matrix.client.userID?.localpart,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
