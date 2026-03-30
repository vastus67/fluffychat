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
      // Discord-style panel on web — offset from nav rail.
      return Stack(
        children: [
          appChild,
          _WebCallPanel(
            activeCall: activeCall,
            onClear: _onClear,
          ),
        ],
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

/// Discord-style call panel for web — sits at the top of the content area,
/// to the right of the navigation rail. Uses [MediaQuery] to figure out break-
/// points so it never overlaps the rail.
class _WebCallPanel extends StatelessWidget {
  final ActiveCallState activeCall;
  final VoidCallback onClear;

  const _WebCallPanel({
    required this.activeCall,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600; // AppDestinations.compactWidth
    final isExpanded = screenWidth >= 1024; // AppDestinations.expandedWidth

    // On compact (mobile-like), no nav rail — panel fills full width.
    // On medium, Flutter NavigationRail is ~72px.
    // On expanded, the extended rail is ~256px.
    final double leftOffset;
    if (isCompact) {
      leftOffset = 0;
    } else if (isExpanded) {
      leftOffset = 256;
    } else {
      leftOffset = 72;
    }

    return Positioned(
      top: 0,
      left: leftOffset,
      right: 0,
      child: Material(
        elevation: 8,
        color: Colors.transparent,
        child: _DiscordCallBar(
          activeCall: activeCall,
          onClear: onClear,
        ),
      ),
    );
  }
}

/// The actual Discord-style call bar content: shows both user avatars with a
/// green "connected" ring, call status, and answer/decline/hangup controls.
class _DiscordCallBar extends StatefulWidget {
  final ActiveCallState activeCall;
  final VoidCallback onClear;

  const _DiscordCallBar({
    required this.activeCall,
    required this.onClear,
  });

  @override
  State<_DiscordCallBar> createState() => _DiscordCallBarState();
}

class _DiscordCallBarState extends State<_DiscordCallBar> {
  CallState? _state;
  Duration _callDuration = Duration.zero;
  DateTime? _connectedAt;
  Timer? _durationTimer;

  CallSession get call => widget.activeCall.call;

  @override
  void initState() {
    super.initState();
    _state = call.state;
    call.onCallStateChanged.stream.listen(_onCallStateChanged);
    if (_state == CallState.kConnected) {
      _connectedAt = DateTime.now();
      _startTimer();
    }
  }

  void _onCallStateChanged(CallState state) {
    if (!mounted) return;
    setState(() => _state = state);
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
      final m = _callDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = _callDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
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

  @override
  Widget build(BuildContext context) {
    final isConnected = _isConnected;
    final isRinging = _isIncomingRinging;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F22), // Discord dark
        border: Border(
          bottom: BorderSide(
            color: isConnected
                ? const Color(0xFF43A047) // green when connected
                : const Color(0xFF5865F2), // blurple when ringing
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          // Two avatars side by side with connection indicator
          _AvatarPair(
            myAvatar: _myAvatar,
            myName: _myName,
            theirAvatar: _callerAvatar,
            theirName: _callerName,
            client: widget.activeCall.client,
            isConnected: isConnected,
          ),
          const SizedBox(width: 16),

          // Call info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _statusLabel,
                  style: TextStyle(
                    color: isConnected
                        ? const Color(0xFF43A047)
                        : Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          if (isRinging) ...[
            _BarButton(
              icon: Icons.call,
              color: const Color(0xFF43A047),
              tooltip: 'Answer',
              onTap: () => call.answer(),
            ),
            const SizedBox(width: 8),
            _BarButton(
              icon: Icons.call_end,
              color: const Color(0xFFE53935),
              tooltip: 'Decline',
              onTap: () => call.reject(),
            ),
          ] else if (!_isEnded) ...[
            _BarButton(
              icon: Icons.call_end,
              color: const Color(0xFFE53935),
              tooltip: 'Hang up',
              onTap: () {
                if (call.isRinging && !call.isOutgoing) {
                  call.reject();
                } else {
                  call.hangup(reason: CallErrorCode.userHangup);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Shows two overlapping avatars with a green ring when connected.
class _AvatarPair extends StatelessWidget {
  final Uri? myAvatar;
  final String myName;
  final Uri? theirAvatar;
  final String theirName;
  final Client client;
  final bool isConnected;

  const _AvatarPair({
    required this.myAvatar,
    required this.myName,
    required this.theirAvatar,
    required this.theirName,
    required this.client,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // My avatar (left, slightly behind)
          Positioned(
            left: 0,
            top: 0,
            child: _RingedAvatar(
              mxContent: myAvatar,
              name: myName,
              client: client,
              size: 40,
              showGreen: isConnected,
            ),
          ),
          // Their avatar (right, slightly overlapping)
          Positioned(
            left: 28,
            top: 0,
            child: _RingedAvatar(
              mxContent: theirAvatar,
              name: theirName,
              client: client,
              size: 40,
              showGreen: isConnected,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single avatar with optional green ring indicating a connected call.
class _RingedAvatar extends StatelessWidget {
  final Uri? mxContent;
  final String name;
  final Client client;
  final double size;
  final bool showGreen;

  const _RingedAvatar({
    required this.mxContent,
    required this.name,
    required this.client,
    required this.size,
    required this.showGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 4,
      height: size + 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: showGreen ? const Color(0xFF43A047) : Colors.transparent,
          width: 2,
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
    );
  }
}

/// Small icon button for the call bar.
class _BarButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _BarButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
