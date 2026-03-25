import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/pages/dialer/call_banner.dart';
import 'package:afterdamage/theme/dracula_colors.dart';
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

          const Divider(
            color: DraculaColors.currentLine,
            height: 1,
          ),

          // Primary navigation: Chats + Spaces
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
                  icon: const Icon(FontAwesomeIcons.comments),
                  label: Text(L10n.of(context).chats),
                ),
                NavigationRailDestination(
                  icon: const Icon(FontAwesomeIcons.globe),
                  label: Text(L10n.of(context).spaces),
                ),
              ],
            ),
          ),

          // Panic Button
          const Divider(
            color: DraculaColors.currentLine,
            height: 1,
          ),
          _NavRailPanicButton(
            extended: extended,
          ),

          // Panic action button
          const Divider(
            color: DraculaColors.currentLine,
            height: 1,
          ),
          _NavRailPanicButton(
            extended: extended,
          ),

          // Discord-style call panel (sits above settings, below nav)
          const GlobalCallSidebar(),

          // Settings gear at the bottom
          const Divider(
            color: DraculaColors.currentLine,
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
    final color = isSelected ? accentColor : DraculaColors.foreground;
    return InkWell(
      onTap: () => context.go('/rooms/settings'),
      child: Container(
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: extended ? 16 : 0),
        child: Row(
          mainAxisAlignment:
              extended ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.gear, color: color, size: 20),
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
    const color = DraculaColors.foreground;
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
            const Icon(FontAwesomeIcons.radiation, color: color, size: 20),
            if (extended) ...[
              const SizedBox(width: 12),
              const Text(
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
