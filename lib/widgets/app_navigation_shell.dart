import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
/// Call UI is handled globally by [_CallScreenRoot] in [FluffyChatApp],
/// so this widget only concerns itself with layout.
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
          return Scaffold(
            key: scaffoldKey,
            drawer: const AppDrawer(),
            body: body,
            bottomNavigationBar: const AppBottomBar(),
          );
        } else {
          return Scaffold(
            key: scaffoldKey,
            body: Row(
              children: [
                AppNavRail(extended: isExpanded),
                // _WebBodyCallWrapper confines the call panel to the chat
                // area only — the nav rail is never covered.
                Expanded(child: _WebBodyCallWrapper(child: body)),
              ],
            ),
            floatingActionButton: floatingActionButton,
          );
        }
      },
    );
  }
}

/// Renders the web call panel (Discord-style top strip, ~410px) inside the
/// chat body column so it never overlaps the navigation rail.
/// Uses an explicit [addListener] subscription — same pattern as
/// [_CallScreenRoot] — so it fires immediately on every notification.
class _WebBodyCallWrapper extends StatefulWidget {
  final Widget child;
  const _WebBodyCallWrapper({required this.child});

  @override
  State<_WebBodyCallWrapper> createState() => _WebBodyCallWrapperState();
}

class _WebBodyCallWrapperState extends State<_WebBodyCallWrapper> {
  static const double _kPanelHeight = 410;

  ValueNotifier<ActiveCallState?>? _notifier;
  ActiveCallState? _activeCall;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!kIsWeb) return;
    final newNotifier = Matrix.of(context).activeCallNotifier;
    if (newNotifier != _notifier) {
      _notifier?.removeListener(_onCallChanged);
      _notifier = newNotifier;
      _notifier!.addListener(_onCallChanged);
      _activeCall = _notifier!.value;
    }
  }

  void _onCallChanged() {
    if (!mounted) return;
    setState(() => _activeCall = _notifier?.value);
  }

  @override
  void dispose() {
    _notifier?.removeListener(_onCallChanged);
    super.dispose();
  }

  void _onClear() {
    final m = Matrix.of(context);
    m.activeCallNotifier.value = null;
    m.callExpandedNotifier.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final activeCall = _activeCall;
    if (activeCall == null) return widget.child;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _kPanelHeight,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color(0x88000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: CallScreen(
              call: activeCall.call,
              client: activeCall.client,
              showTopBar: true,
              onClear: _onClear,
            ),
          ),
        ),
      ],
    );
  }
}
