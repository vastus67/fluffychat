import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/theme/dracula_colors.dart';
import 'package:afterdamage/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:afterdamage/widgets/app_destinations.dart';
import 'package:afterdamage/widgets/avatar.dart';
import 'package:afterdamage/widgets/matrix.dart';

/// Navigation rail for desktop and web layouts
class AppNavRail extends StatelessWidget {
  final bool extended;

  const AppNavRail({
    super.key,
    this.extended = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = Matrix.of(context).client;
    final currentRoute = GoRouter.of(context).routeInformationProvider.value.uri.path;
    final destinations = AppDestinations.getDestinations(context);

    // Find the selected index based on current route
    int selectedIndex = 0;
    for (int i = 0; i < destinations.length; i++) {
      if (currentRoute.startsWith(destinations[i].route)) {
        selectedIndex = i;
        break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: DraculaColors.background,
        border: Border(
          right: BorderSide(
            color: DraculaColors.currentLine,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // User header (compact on rail)
          _buildUserHeader(context, client, theme, extended),
          const Divider(
            color: DraculaColors.currentLine,
            height: 1,
          ),

          // Navigation Rail
          Expanded(
            child: NavigationRail(
              extended: extended,
              backgroundColor: DraculaColors.background,
              selectedIconTheme: IconThemeData(
                color: theme.colorScheme.primary,
              ),
              unselectedIconTheme: const IconThemeData(
                color: DraculaColors.foreground,
              ),
              selectedLabelTextStyle: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: DraculaColors.foreground,
              ),
              indicatorColor: theme.colorScheme.primary.withOpacity(0.15),
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                if (index >= 0 && index < destinations.length) {
                  context.go(destinations[index].route);
                }
              },
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: destinations
                  .map(
                    (dest) => NavigationRailDestination(
                      icon: Icon(dest.icon),
                      label: Text(dest.getLabel(context)),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Footer
          if (extended)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: DraculaColors.currentLine,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'Afterdamage Chat',
                style: TextStyle(
                  color: DraculaColors.muted,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(
    BuildContext context,
    Client client,
    ThemeData theme,
    bool extended,
  ) {
    final profile = client.fetchOwnProfile();

    return FutureBuilder<Profile>(
      future: profile,
      builder: (context, snapshot) {
        final displayName = snapshot.data?.displayName ??
            client.userID?.localpart ??
            '';
        final avatarUrl = snapshot.data?.avatarUrl;

        if (!extended) {
          // Compact header - just avatar
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Tooltip(
              message: displayName,
              child: Avatar(
                mxContent: avatarUrl,
                name: displayName,
                size: 40,
              ),
            ),
          );
        }

        // Extended header - avatar + name
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: DraculaColors.currentLine,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Avatar(
                mxContent: avatarUrl,
                name: displayName,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: DraculaColors.foreground,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      client.userID ?? '',
                      style: TextStyle(
                        color: DraculaColors.muted,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
