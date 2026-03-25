import 'package:flutter/material.dart';

import 'package:afterdamage/config/themes.dart';
import 'package:afterdamage/pages/dialer/call_banner.dart';

class TwoColumnLayout extends StatelessWidget {
  final Widget mainView;
  final Widget sideView;

  const TwoColumnLayout({
    super.key,
    required this.mainView,
    required this.sideView,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ScaffoldMessenger(
      child: Scaffold(
        body: Row(
          children: [
            // Left sidebar: chat list + call panel at bottom
            SizedBox(
              width: FluffyThemes.columnWidth + FluffyThemes.navRailWidth,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(),
                      child: mainView,
                    ),
                  ),
                  // Discord-style call sidebar panel
                  const GlobalCallSidebar(),
                ],
              ),
            ),
            Container(width: 1.0, color: theme.dividerColor),
            // Right side: call panel on top + chat content below
            Expanded(
              child: Column(
                children: [
                  const GlobalCallFloatingPanel(),
                  Expanded(child: ClipRRect(child: sideView)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
