import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dart:async';

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
import 'package:afterdamage/widgets/avatar.dart';
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
/// * **Web / browser**: Discord-style compact panel at the top of the screen,
///   offset to the right of the nav rail so it never covers navigation.
/// * **Native / PWA**: full-screen overlay.
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
    final activeCall = _activeCall;
    if (activeCall == null) return appChild;

    if (kIsWeb) {
      // Discord-style: call area on top, app content below — no overlay.
      return _WebCallPanel(
        activeCall: activeCall,
        onClear: _onClear,
        appChild: appChild,
      );
    }

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

/// Discord-style call panel for web.
///
/// Instead of overlaying on top of everything (which covers the nav rail and
/// DM list), this widget injects itself into the child's layout using a
/// [Column]: call area on top, original app child below. The call area is
/// only as tall as it needs to be and never covers navigation.
///
/// When there is no active call, [_CallScreenRoot] returns [appChild] directly
/// so this widget is never mounted.
class _WebCallPanel extends StatefulWidget {
  final ActiveCallState activeCall;
  final VoidCallback onClear;
  final Widget appChild;

  const _WebCallPanel({
    required this.activeCall,
    required this.onClear,
    required this.appChild,
  });

  @override
  State<_WebCallPanel> createState() => _WebCallPanelState();
}

class _WebCallPanelState extends State<_WebCallPanel> {
  CallState? _state;
  Duration _callDuration = Duration.zero;
  DateTime? _connectedAt;
  Timer? _durationTimer;
  bool _isMicMuted = false;

  CallSession get call => widget.activeCall.call;

  @override
  void initState() {
    super.initState();
    _state = call.state;
    _isMicMuted = call.isMicrophoneMuted;
    call.onCallStateChanged.stream.listen(_onCallStateChanged);
    if (_state == CallState.kConnected) {
      _connectedAt = DateTime.now();
      _startTimer();
    }
  }

  void _onCallStateChanged(CallState state) {
    if (!mounted) return;
    setState(() {
      _state = state;
      _isMicMuted = call.isMicrophoneMuted;
    });
    if (state == CallState.kConnected && _connectedAt == null) {
      _connectedAt = DateTime.now();
      _startTimer();
    }
    if (state == CallState.kEnded || state == CallState.kEnding) {
      _durationTimer?.cancel();
      Timer(const Duration(seconds: 2), () {
        if (mounted) widget.onClear();
      });
    }
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _connectedAt == null) return;
      setState(() {
        _callDuration = DateTime.now().difference(_connectedAt!);
      });
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  bool get _isIncomingRinging =>
      _state == CallState.kRinging && !call.isOutgoing;
  bool get _isConnected => _state == CallState.kConnected;
  bool get _isEnded =>
      _state == CallState.kEnded || _state == CallState.kEnding;

  String get _statusLabel {
    if (_isEnded) return 'Call ended';
    if (_isConnected) {
      final h = _callDuration.inHours;
      final m =
          _callDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s =
          _callDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
      return h > 0 ? '$h:$m:$s' : '$m:$s';
    }
    if (_isIncomingRinging) return 'Incoming call…';
    switch (_state) {
      case CallState.kInviteSent:
      case CallState.kCreateOffer:
        return 'Calling…';
      case CallState.kRinging:
        return 'Ringing…';
      case CallState.kCreateAnswer:
      case CallState.kConnecting:
        return 'Connecting…';
      default:
        return 'Setting up…';
    }
  }

  String get _callerName {
    if (call.room.isDirectChat) {
      final userId = call.room.directChatMatrixID ?? '';
      final user = call.room.unsafeGetUserFromMemoryOrFallback(userId);
      return user.displayName ?? user.id;
    }
    return call.room.getLocalizedDisplayname();
  }

  Uri? get _callerAvatar {
    if (call.room.isDirectChat) {
      final userId = call.room.directChatMatrixID ?? '';
      return call.room.unsafeGetUserFromMemoryOrFallback(userId).avatarUrl;
    }
    return null;
  }

  Uri? get _myAvatar {
    final client = widget.activeCall.client;
    final myId = client.userID;
    if (myId == null) return null;
    final user = call.room.unsafeGetUserFromMemoryOrFallback(myId);
    return user.avatarUrl;
  }

  String get _myName {
    final client = widget.activeCall.client;
    final myId = client.userID;
    if (myId == null) return 'You';
    final user = call.room.unsafeGetUserFromMemoryOrFallback(myId);
    return user.displayName ?? myId.localpart ?? 'You';
  }

  Future<void> _toggleMic() async {
    try {
      await call.setMicrophoneMuted(!call.isMicrophoneMuted);
    } catch (e) {
      Logs().w('[WebCallPanel] setMicrophoneMuted error: $e');
    }
    if (mounted) setState(() => _isMicMuted = call.isMicrophoneMuted);
  }

  void _hangUp() {
    if (call.isRinging && !call.isOutgoing) {
      call.reject();
    } else {
      call.hangup(reason: CallErrorCode.userHangup);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The call area sits ABOVE the normal app content in a Column,
    // so it never overlays the nav rail or sidebar.
    return Column(
      children: [
        // ── Call area (Discord-style) ──
        _buildCallArea(),
        // ── Original app content fills the rest ──
        Expanded(child: widget.appChild),
      ],
    );
  }

  Widget _buildCallArea() {
    final isConnected = _isConnected;
    final isRinging = _isIncomingRinging;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF2B2D31), // Discord dark surface
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E1F22), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Main call display ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            color: const Color(0xFF111214),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Two avatars side by side
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CallAvatar(
                      mxContent: _myAvatar,
                      name: _myName,
                      client: widget.activeCall.client,
                      isConnected: isConnected,
                    ),
                    const SizedBox(width: 24),
                    _CallAvatar(
                      mxContent: _callerAvatar,
                      name: _callerName,
                      client: widget.activeCall.client,
                      isConnected: isConnected,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Status text
                Text(
                  _statusLabel,
                  style: TextStyle(
                    color: isConnected
                        ? const Color(0xFF43A047)
                        : Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // ── Controls bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF2B2D31),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mic toggle
                _ControlPill(
                  icon: _isMicMuted ? Icons.mic_off : Icons.mic,
                  active: _isMicMuted,
                  onTap: _toggleMic,
                  tooltip: _isMicMuted ? 'Unmute' : 'Mute',
                ),
                const SizedBox(width: 8),

                if (isRinging) ...[
                  // Answer button
                  _ControlPill(
                    icon: Icons.call,
                    color: const Color(0xFF43A047),
                    onTap: () => call.answer(),
                    tooltip: 'Answer',
                  ),
                  const SizedBox(width: 8),
                ],

                // Hang up / Decline
                _ControlPill(
                  icon: Icons.call_end,
                  color: const Color(0xFFE53935),
                  onTap: isRinging ? () => call.reject() : _hangUp,
                  tooltip: isRinging ? 'Decline' : 'Hang up',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Large circular avatar for the Discord-style call area.
/// Shows a green ring when the call is connected.
class _CallAvatar extends StatelessWidget {
  final Uri? mxContent;
  final String name;
  final Client client;
  final bool isConnected;

  const _CallAvatar({
    required this.mxContent,
    required this.name,
    required this.client,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 80;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size + 6,
          height: size + 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  isConnected ? const Color(0xFF43A047) : Colors.transparent,
              width: 3,
            ),
          ),
          child: ClipOval(
            child: Avatar(
              mxContent: mxContent,
              name: name,
              size: size,
              client: client,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Rounded pill button for call controls (matches Discord's style).
class _ControlPill extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final bool active;
  final VoidCallback onTap;
  final String tooltip;

  const _ControlPill({
    required this.icon,
    this.color,
    this.active = false,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? (active ? Colors.white : const Color(0xFF3C3F44));
    final fg = color != null
        ? Colors.white
        : (active ? Colors.black : Colors.white);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Icon(icon, color: fg, size: 20),
          ),
        ),
      ),
    );
  }
}
