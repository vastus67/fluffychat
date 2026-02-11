import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Represents a navigation destination in the app
class AppDestination {
  final String id;
  final IconData icon;
  final String Function(BuildContext) labelBuilder;
  final String route;

  const AppDestination({
    required this.id,
    required this.icon,
    required this.labelBuilder,
    required this.route,
  });

  String getLabel(BuildContext context) => labelBuilder(context);
}

/// Central list of all app navigation destinations
class AppDestinations {
  static List<AppDestination> getDestinations(BuildContext context) {
    return [
      AppDestination(
        id: 'home',
        icon: FontAwesomeIcons.house,
        labelBuilder: (context) {
          // Import L10n dynamically to avoid circular dependencies
          final l10n = Localizations.of(context, dynamic);
          return l10n?.chats ?? 'Chats';
        },
        route: '/rooms',
      ),
      AppDestination(
        id: 'settings',
        icon: FontAwesomeIcons.gear,
        labelBuilder: (context) {
          final l10n = Localizations.of(context, dynamic);
          return l10n?.settings ?? 'Settings';
        },
        route: '/rooms/settings',
      ),
      AppDestination(
        id: 'account',
        icon: FontAwesomeIcons.circleUser,
        labelBuilder: (context) {
          final l10n = Localizations.of(context, dynamic);
          return l10n?.yourOwnUsername ?? 'Account';
        },
        route: '/rooms/settings/account',
      ),
      AppDestination(
        id: 'notifications',
        icon: FontAwesomeIcons.bell,
        labelBuilder: (context) {
          final l10n = Localizations.of(context, dynamic);
          return l10n?.notifications ?? 'Notifications';
        },
        route: '/rooms/settings/notifications',
      ),
      AppDestination(
        id: 'archive',
        icon: FontAwesomeIcons.boxArchive,
        labelBuilder: (context) {
          final l10n = Localizations.of(context, dynamic);
          return l10n?.archive ?? 'Archive';
        },
        route: '/rooms/archive',
      ),
      AppDestination(
        id: 'theme',
        icon: FontAwesomeIcons.paintbrush,
        labelBuilder: (context) {
          final l10n = Localizations.of(context, dynamic);
          return l10n?.changeTheme ?? 'Theme';
        },
        route: '/rooms/settings/style',
      ),
      AppDestination(
        id: 'about',
        icon: FontAwesomeIcons.circleInfo,
        labelBuilder: (context) {
          final l10n = Localizations.of(context, dynamic);
          return l10n?.about ?? 'About';
        },
        route: '/rooms/settings/about',
      ),
    ];
  }

  /// Responsive breakpoints for navigation layout
  static const double compactWidth = 600;
  static const double expandedWidth = 1024;

  static bool isCompact(BuildContext context) {
    return MediaQuery.of(context).size.width < compactWidth;
  }

  static bool isExpanded(BuildContext context) {
    return MediaQuery.of(context).size.width >= expandedWidth;
  }

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= compactWidth && width < expandedWidth;
  }
}
