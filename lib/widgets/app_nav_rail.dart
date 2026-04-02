import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/ui/icons/afterdamage_icons.dart';

import 'package:afterdamage/widgets/avatar.dart';
import 'package:afterdamage/widgets/matrix.dart';
import 'package:afterdamage/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:afterdamage/widgets/future_loading_dialog.dart';

/// Navigation rail for desktop and web layouts.
///
/// Shows: User header, New Chat button, Chats, Spaces, Settings (bottom).
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
    final currentRoute =
        GoRouter.of(context).routeInformationProvider.value.uri.path;

    // Determine which primary item is active
    final isOnSpaces = currentRoute.startsWith('/rooms/spaces') ||
        currentRoute.contains('spaceId=');
    final isOnSettings = currentRoute.startsWith('/rooms/settings');

    // Selected index: 0=Chats, 1=Spaces
    final selectedIndex = isOnSpaces ? 1 : 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // User header (compact on rail)
          _buildUserHeader(context, client, theme, extended),
          Divider(
            color: theme.dividerColor,
            height: 1,
          ),

          // New Chat action button
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: extended ? 16 : 12,
              vertical: 12,
            ),
            child: extended
                ? FilledButton.icon(
                    onPressed: () => context.go('/rooms/newprivatechat'),
                    icon: AfterdamageIcons.newChat(context, size: 18),
                    label: Text(L10n.of(context).newChat),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  )
                : IconButton.filled(
                    onPressed: () => context.go('/rooms/newprivatechat'),
                    icon: AfterdamageIcons.newChat(context, size: 20),
                    tooltip: L10n.of(context).newChat,
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor:
                          ThemeData.estimateBrightnessForColor(
                                    theme.colorScheme.primary,
                                  ) ==
                                  Brightness.dark
                              ? Colors.white
                              : Colors.black,
                    ),
                  ),
          ),

          Divider(
            color: theme.dividerColor,
            height: 1,
          ),

          // Primary navigation: Chats + Spaces
          Expanded(
            child: NavigationRail(
              extended: extended,
              backgroundColor: theme.colorScheme.surface,
              selectedIconTheme: IconThemeData(
                color: theme.colorScheme.primary,
              ),
              unselectedIconTheme: IconThemeData(
                color: theme.colorScheme.onSurface,
              ),
              selectedLabelTextStyle: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: theme.colorScheme.onSurface,
              ),
              indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              selectedIndex: isOnSettings ? null : selectedIndex,
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/rooms');
                    break;
                  case 1:
                    context.go('/rooms/spaces');
                    break;
                }
              },
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(
                  icon: const FaIcon(FontAwesomeIcons.comments),
                  label: Text(L10n.of(context).chats),
                ),
                NavigationRailDestination(
                  icon: const FaIcon(FontAwesomeIcons.globe),
                  label: Text(L10n.of(context).spaces),
                ),
              ],
            ),
          ),

          // Panic Button
          Divider(
            color: theme.dividerColor,
            height: 1,
          ),
          _NavRailPanicButton(
            extended: extended,
          ),

          // Settings gear at the bottom
          Divider(
            color: theme.dividerColor,
            height: 1,
          ),
          _NavRailSettingsButton(
            isSelected: isOnSettings,
            extended: extended,
            accentColor: theme.colorScheme.primary,
          ),

          // Footer
          if (extended)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'Afterdamage Chat',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
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
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
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
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
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

/// Bottom-pinned settings button for the nav rail.
class _NavRailSettingsButton extends StatelessWidget {
  final bool isSelected;
  final bool extended;
  final Color accentColor;

  const _NavRailSettingsButton({
    required this.isSelected,
    required this.extended,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? accentColor : Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: () => context.go('/rooms/settings'),
      child: Container(
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: extended ? 16 : 0),
        child: Row(
          mainAxisAlignment:
              extended ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.gear, color: color, size: 20),
            if (extended) ...[
              const SizedBox(width: 12),
              Text(
                L10n.of(context).settings,
                style: TextStyle(
                  color: color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Panic button for the nav rail.
class _NavRailPanicButton extends StatelessWidget {
  final bool extended;

  const _NavRailPanicButton({
    required this.extended,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: () async {
        final consent = await showOkCancelAlertDialog(
          context: context,
          title: 'Panic',
          message: 'This will wipe all local data and log you out. Are you absolutely sure?',
          okLabel: 'Burn it',
          cancelLabel: L10n.of(context).cancel,
        );
        if (consent != OkCancelResult.ok || !context.mounted) return;
        
        await showFutureLoadingDialog(
          context: context,
          future: () async {
            await Matrix.of(context).client.clearCache();
            try {
              await Matrix.of(context).client.logout();
            } catch (_) {}
          },
        );
        
        if (!context.mounted) return;
        context.go('/');
      },
      child: Container(
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: extended ? 16 : 0),
        child: Row(
          mainAxisAlignment:
              extended ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.radiation, color: color, size: 20),
            if (extended) ...[
              const SizedBox(width: 12),
              Text(
                'Panic',
                style: TextStyle(
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
