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
        body: Column(
          children: [
            const GlobalCallBanner(),
            Expanded(
              child: Row(
                children: [
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(),
                    width: FluffyThemes.columnWidth + FluffyThemes.navRailWidth,
                    child: mainView,
                  ),
                  Container(width: 1.0, color: theme.dividerColor),
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
