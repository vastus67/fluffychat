import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:afterdamage/config/routes.dart';
import 'package:afterdamage/config/setting_keys.dart';
import 'package:afterdamage/config/themes.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/pages/dialer/call_screen.dart';
import 'package:afterdamage/theme/dracula_accents.dart';
import 'package:afterdamage/utils/voip_plugin.dart';
import 'package:afterdamage/widgets/app_lock.dart';
import 'package:afterdamage/widgets/matrix.dart';
import 'package:afterdamage/widgets/theme_builder.dart';
import '../utils/custom_scroll_behaviour.dart';

class FluffyChatApp extends StatelessWidget {
  final Widget? testWidget;
  final List<Client> clients;
  final String? pincode;
  final SharedPreferences store;

  const FluffyChatApp({
    super.key,
    this.testWidget,
    required this.clients,
    required this.store,
    this.pincode,
  });

  /// getInitialLink may rereturn the value multiple times if this view is
  /// opened multiple times for example if the user logs out after they logged
  /// in with qr code or magic link.
  static bool gotInitialLink = false;

  // Router must be outside of build method so that hot reload does not reset
  // the current path.
  static final GoRouter router = GoRouter(
    routes: AppRoutes.routes,
    debugLogDiagnostics: true,
  );

  @override
  Widget build(BuildContext context) {
    return ThemeBuilder(
      builder: (context, themeMode, primaryColor) {
        // Get the current Dracula accent from settings
        final accentName = AppSettings.draculaAccent.value;
        final draculaAccent = DraculaAccent.values.firstWhere(
          (accent) => accent.name == accentName,
          orElse: () => DraculaAccent.red,  // Default to red accent
        );

        return MaterialApp.router(
          title: AppSettings.applicationName.value,
          themeMode: themeMode,
          // Use light theme with Dracula accent as seed color
          theme: FluffyThemes.buildTheme(
            context,
            Brightness.light,
            draculaAccent.previewColor,
          ),
          // Use Dracula accent theme for dark mode
          darkTheme: FluffyThemes.buildAccentTheme(
            context,
            draculaAccent,
          ),
          scrollBehavior: CustomScrollBehavior(),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          routerConfig: router,
          builder: (context, child) => AppLockWidget(
            pincode: pincode,
            clients: clients,
            // Need a navigator above the Matrix widget for
            // displaying dialogs
            child: Matrix(
              clients: clients,
              store: store,
              // _CallScreenRoot wraps the entire router so the call UI
              // is always present regardless of which route is active.
              child: _CallScreenRoot(child: testWidget ?? child),
            ),
          ),
        );
      },
    );
  }
}

/// Wraps the entire app so the call UI is always present on every route.
///
/// MUST be a [StatefulWidget] — explicit [addListener] subscription ensures
/// the overlay fires immediately on every notification regardless of parent
/// rebuild schedule.
///
/// * **Web / browser**: call panel is rendered by [_WebBodyCallWrapper] inside
///   [AppNavigationShell]'s body column, so it only covers the chat area and
///   never overlaps the nav rail.
/// * **Native / PWA** (`kIsWeb == false`): full-screen overlay here.
class _CallScreenRoot extends StatefulWidget {
  final Widget? child;
  const _CallScreenRoot({this.child});

  @override
  State<_CallScreenRoot> createState() => _CallScreenRootState();
}

class _CallScreenRootState extends State<_CallScreenRoot> {
  ValueNotifier<ActiveCallState?>? _notifier;
  ActiveCallState? _activeCall;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // On web the panel is rendered inside AppNavigationShell body; skip here.
    if (kIsWeb) return;
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
    final appChild = widget.child ?? const SizedBox.shrink();

    // Web: panel is in AppNavigationShell — pass through unchanged.
    if (kIsWeb) return appChild;

    final activeCall = _activeCall;
    if (activeCall == null) return appChild;

    // Native (Android / iOS / desktop): full-screen overlay.
    return Stack(
      fit: StackFit.expand,
      children: [
        appChild,
        CallScreen(
          call: activeCall.call,
          client: activeCall.client,
          onClear: _onClear,
        ),
      ],
    );
  }
}
