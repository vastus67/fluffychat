import 'package:flutter/material.dart';

import 'package:afterdamage/pages/dialer/call_banner.dart';
import 'package:afterdamage/widgets/app_bottom_bar.dart';
import 'package:afterdamage/widgets/app_destinations.dart';
import 'package:afterdamage/widgets/app_drawer.dart';
import 'package:afterdamage/widgets/app_nav_rail.dart';

/// Responsive navigation shell that provides drawer on mobile
/// and persistent navigation rail on desktop/web
class AppNavigationShell extends StatelessWidget {
  final Widget body;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Widget? floatingActionButton;

  const AppNavigationShell({
    super.key,
    required this.body,
    this.scaffoldKey,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = AppDestinations.isCompact(context);
        final isExpanded = AppDestinations.isExpanded(context);

        if (isCompact) {
          // Mobile: Use drawer + bottom toolbar (replaces FAB)
          // Call sidebar panel shows above bottom bar
          return Scaffold(
            key: scaffoldKey,
            drawer: const AppDrawer(),
            body: Column(
              children: [
                const GlobalCallFloatingPanel(),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: body),
                      const GlobalCallSidebar(),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: const AppBottomBar(),
          );
        } else {
          // Desktop/Web: Use persistent navigation rail
          // Call panel is already in AppNavRail; floating panel overlays content
          return Scaffold(
            key: scaffoldKey,
            body: Row(
              children: [
                AppNavRail(extended: isExpanded),
                Expanded(
                  child: Column(
                    children: [
                      const GlobalCallFloatingPanel(),
                      Expanded(child: body),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: floatingActionButton,
          );
        }
      },
    );
  }
}
