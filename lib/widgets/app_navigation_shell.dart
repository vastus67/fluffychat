import 'package:flutter/material.dart';

import 'package:afterdamage/pages/dialer/call_banner.dart';
import 'package:afterdamage/pages/dialer/call_screen.dart';
import 'package:afterdamage/utils/voip_plugin.dart';
import 'package:afterdamage/widgets/app_bottom_bar.dart';
import 'package:afterdamage/widgets/app_destinations.dart';
import 'package:afterdamage/widgets/app_drawer.dart';
import 'package:afterdamage/widgets/app_nav_rail.dart';
import 'package:afterdamage/widgets/matrix.dart';

/// Responsive navigation shell that provides drawer on mobile
/// and persistent navigation rail on desktop/web.
///
/// On mobile the full-screen [CallScreen] is stacked on top of the
/// scaffold whenever a call is active (incoming, outgoing, or connected).
/// This Stack approach is reliable because this widget lives *inside* the
/// Navigator/Overlay tree, unlike [VoipPlugin] whose context sits above it.
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
        final voipPlugin = Matrix.of(context).voipPlugin;

        if (isCompact) {
          // Mobile: drawer + bottom bar. Call screen overlays everything via
          // a Stack — no GlobalCallSidebar or GlobalCallFloatingPanel here.
          final scaffold = Scaffold(
            key: scaffoldKey,
            drawer: const AppDrawer(),
            body: body,
            bottomNavigationBar: const AppBottomBar(),
          );

          if (voipPlugin == null) return scaffold;

          return ValueListenableBuilder<ActiveCallState?>(
            valueListenable: voipPlugin.activeCallNotifier,
            builder: (ctx, activeCall, child) {
              if (activeCall == null) return child!;

              return Stack(
                children: [
                  child!,
                  Positioned.fill(
                    child: CallScreen(
                      call: activeCall.call,
                      client: activeCall.client,
                      onClear: () {
                        voipPlugin.activeCallNotifier.value = null;
                        voipPlugin.callExpandedNotifier.value = false;
                      },
                    ),
                  ),
                ],
              );
            },
            child: scaffold,
          );
        } else {
          // Desktop/Web: persistent navigation rail.
          // Same Stack approach used for mobile so the CallScreen appears
          // reliably regardless of whether the user is on the correct route.
          final scaffold = Scaffold(
            key: scaffoldKey,
            body: Row(
              children: [
                AppNavRail(extended: isExpanded),
                Expanded(child: body),
              ],
            ),
            floatingActionButton: floatingActionButton,
          );

          if (voipPlugin == null) return scaffold;

          return ValueListenableBuilder<ActiveCallState?>(
            valueListenable: voipPlugin.activeCallNotifier,
            builder: (ctx, activeCall, child) {
              if (activeCall == null) return child!;

              return Stack(
                children: [
                  child!,
                  Positioned.fill(
                    child: CallScreen(
                      call: activeCall.call,
                      client: activeCall.client,
                      onClear: () {
                        voipPlugin.activeCallNotifier.value = null;
                        voipPlugin.callExpandedNotifier.value = false;
                      },
                    ),
                  ),
                ],
              );
            },
            child: scaffold,
          );
        }
      },
    );
  }
}
