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
/// Lives inside [Matrix] so it can read [VoipPlugin] and subscribe to
/// [VoipPlugin.activeCallNotifier].
///
/// * **Web / browser**: shows a floating draggable window (Discord-style).
/// * **Native mobile / desktop**: shows a full-screen overlay.
class _CallScreenRoot extends StatelessWidget {
  final Widget? child;
  const _CallScreenRoot({this.child});

  @override
  Widget build(BuildContext context) {
    final voipPlugin = Matrix.of(context).voipPlugin;

    if (voipPlugin == null) return child ?? const SizedBox.shrink();

    return ValueListenableBuilder<ActiveCallState?>(
      valueListenable: voipPlugin.activeCallNotifier,
      builder: (ctx, activeCall, appChild) {
        if (activeCall == null) return appChild ?? const SizedBox.shrink();

        void onClear() {
          voipPlugin.activeCallNotifier.value = null;
          voipPlugin.callExpandedNotifier.value = false;
        }

        if (kIsWeb) {
          // Floating draggable window on web/PWA-desktop.
          return Stack(
            children: [
              if (appChild != null) appChild,
              _CallWindowOverlay(activeCall: activeCall, onClear: onClear),
            ],
          );
        }

        // Full-screen overlay on native mobile/desktop.
        return Stack(
          children: [
            if (appChild != null) appChild,
            Positioned.fill(
              child: CallScreen(
                call: activeCall.call,
                client: activeCall.client,
                onClear: onClear,
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }
}

/// Floating draggable call window for web — mirrors Discord's in-browser call
/// overlay. Centered on first appearance, draggable via the title bar strip,
/// and clamped to the screen bounds.
class _CallWindowOverlay extends StatefulWidget {
  final ActiveCallState activeCall;
  final VoidCallback onClear;

  const _CallWindowOverlay({
    required this.activeCall,
    required this.onClear,
  });

  @override
  State<_CallWindowOverlay> createState() => _CallWindowOverlayState();
}

class _CallWindowOverlayState extends State<_CallWindowOverlay> {
  static const double _w = 360;
  static const double _h = 500; // 36px title bar + 464px content

  Offset? _offset;

  String get _windowTitle {
    final call = widget.activeCall.call;
    final isVideo = call.type == CallType.kVideo;
    if (call.state == CallState.kRinging && !call.isOutgoing) {
      return isVideo ? 'Incoming video call' : 'Incoming call';
    }
    return isVideo ? 'Video call' : 'Voice call';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxLeft = (size.width - _w).clamp(0.0, size.width);
    final maxTop = (size.height - _h).clamp(0.0, size.height);

    final left = (_offset?.dx ?? (size.width - _w) / 2).clamp(0.0, maxLeft);
    final top = (_offset?.dy ?? (size.height - _h) / 2.5).clamp(0.0, maxTop);

    return Positioned(
      left: left,
      top: top,
      width: _w,
      height: _h,
      child: Material(
        elevation: 24,
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // ── Drag handle title bar ──────────────────────────────────
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) {
                setState(() {
                  _offset = Offset(
                    (left + details.delta.dx).clamp(0.0, maxLeft),
                    (top + details.delta.dy).clamp(0.0, maxTop),
                  );
                });
              },
              child: Container(
                height: 36,
                color: const Color(0xFF12121F),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.drag_indicator,
                      color: Colors.white38,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _windowTitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Call screen content ────────────────────────────────────
            Expanded(
              child: CallScreen(
                call: widget.activeCall.call,
                client: widget.activeCall.client,
                showTopBar: false,
                onClear: widget.onClear,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
