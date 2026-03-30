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

  // Key used to access the Navigator's Overlay for call UI insertion.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Router must be outside of build method so that hot reload does not reset
  // the current path.
  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
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
/// The call UI is inserted as an [OverlayEntry] inside the [Navigator]'s own
/// [Overlay] (accessed via [FluffyChatApp.navigatorKey]). This ensures that
/// [CallScreen] has proper widget ancestors (Overlay, Navigator, Material)
/// — placing it as a sibling to the Navigator in a Stack would crash because
/// Tooltip / IconButton / etc. inside CallScreen need an Overlay ancestor.
///
/// * **Web column mode**: half-screen panel over the right content pane.
/// * **Web narrow / PWA / native**: full-screen overlay.
class _CallScreenRoot extends StatefulWidget {
  final Widget? child;
  const _CallScreenRoot({this.child});

  @override
  State<_CallScreenRoot> createState() => _CallScreenRootState();
}

class _CallScreenRootState extends State<_CallScreenRoot> {
  ValueNotifier<ActiveCallState?>? _notifier;
  ActiveCallState? _activeCall;
  OverlayEntry? _callOverlay;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newNotifier = Matrix.of(context).activeCallNotifier;
    if (newNotifier != _notifier) {
      _notifier?.removeListener(_onCallChanged);
      _notifier = newNotifier;
      _notifier!.addListener(_onCallChanged);
      _activeCall = _notifier!.value;
      if (_activeCall != null && _callOverlay == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _activeCall != null) _insertCallOverlay();
        });
      }
    }
  }

  void _onCallChanged() {
    if (!mounted) return;
    final newCall = _notifier?.value;
    final hadCall = _activeCall != null;
    _activeCall = newCall;

    if (newCall != null && !hadCall) {
      _insertCallOverlay();
    } else if (newCall == null && hadCall) {
      _removeCallOverlay();
    } else if (newCall != null) {
      // Same call, different state — just rebuild the entry.
      _callOverlay?.markNeedsBuild();
    }
  }

  void _insertCallOverlay() {
    if (_callOverlay != null) return;
    final navigatorState = FluffyChatApp.navigatorKey.currentState;
    if (navigatorState == null || navigatorState.overlay == null) {
      // Navigator not mounted yet — retry next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _activeCall != null && _callOverlay == null) {
          _insertCallOverlay();
        }
      });
      return;
    }

    _callOverlay = OverlayEntry(
      builder: (overlayContext) {
        final activeCall = _activeCall;
        if (activeCall == null) return const SizedBox.shrink();
        return _buildCallUI(overlayContext, activeCall);
      },
    );
    navigatorState.overlay!.insert(_callOverlay!);
  }

  void _removeCallOverlay() {
    _callOverlay?.remove();
    _callOverlay = null;
  }

  @override
  void dispose() {
    _removeCallOverlay();
    _notifier?.removeListener(_onCallChanged);
    super.dispose();
  }

  void _onClear() {
    final m = Matrix.of(context);
    m.activeCallNotifier.value = null;
    m.callExpandedNotifier.value = false;
  }

  /// Builds the call UI widget. Returned directly inside the Navigator's
  /// Overlay, so [Positioned] is supported (the Overlay uses a Stack).
  Widget _buildCallUI(BuildContext overlayContext, ActiveCallState activeCall) {
    if (kIsWeb) {
      final isColumnMode = FluffyThemes.isColumnMode(overlayContext);

      if (!isColumnMode) {
        // Narrow screen (phone PWA / small browser): full-screen call.
        return CallScreen(
          call: activeCall.call,
          client: activeCall.client,
          onClear: _onClear,
        );
      }

      // Desktop web column mode: half-screen on the right content pane.
      final leftOffset =
          FluffyThemes.columnWidth + FluffyThemes.navRailWidth + 1.0;
      final screenHeight = MediaQuery.of(overlayContext).size.height;

      return Positioned(
        top: 0,
        left: leftOffset,
        right: 0,
        height: screenHeight * 0.5,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          child: CallScreen(
            call: activeCall.call,
            client: activeCall.client,
            onClear: _onClear,
          ),
        ),
      );
    }

    // Native (Android / iOS / desktop): full-screen overlay.
    return CallScreen(
      call: activeCall.call,
      client: activeCall.client,
      onClear: _onClear,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Call UI is managed entirely via OverlayEntry — just pass through child.
    return widget.child ?? const SizedBox.shrink();
  }
}

