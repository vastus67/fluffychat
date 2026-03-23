import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' hide VideoRenderer;
import 'package:matrix/matrix.dart';

import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:afterdamage/utils/platform_infos.dart';
import 'package:afterdamage/utils/voip/remote_audio_player.dart';
import 'package:afterdamage/utils/voip/video_renderer.dart';
import 'package:afterdamage/widgets/avatar.dart';

/// A compact Discord-style call panel that shows inline instead of fullscreen.
/// Used on web and optionally on desktop. Shows call status, participant info,
/// and controls in a small bar/panel.
class CallBanner extends StatefulWidget {
  final BuildContext callContext;
  final String callId;
  final CallSession call;
  final Client client;
  final VoidCallback? onClear;
  final VoidCallback? onExpand;

  const CallBanner({
    required this.callContext,
    required this.callId,
    required this.call,
    required this.client,
    this.onClear,
    this.onExpand,
    super.key,
  });

  @override
  State<CallBanner> createState() => _CallBannerState();
}

class _CallBannerState extends State<CallBanner> {
  CallSession get call => widget.call;

  String get displayName => call.room.getLocalizedDisplayname(
        MatrixLocals(L10n.of(widget.callContext)),
      );

  bool get voiceonly => call.type == CallType.kVoice;
  bool get connected => call.state == CallState.kConnected;
  bool get isMicrophoneMuted => call.isMicrophoneMuted;
  bool get isLocalVideoMuted => call.isLocalVideoMuted;

  CallState? _state;
  Timer? _durationTimer;
  Duration _callDuration = Duration.zero;
  DateTime? _connectedAt;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _state = call.state;
    call.onCallStateChanged.stream.listen(_handleCallState);
    call.onCallEventChanged.stream.listen((event) {
      if (event == CallStateChange.kFeedsChanged) {
        setState(() {
          call.tryRemoveStopedStreams();
        });
      }
    });
  }

  void _handleCallState(CallState state) {
    if (!mounted) return;
    setState(() {
      _state = state;
      if (state == CallState.kConnected && _connectedAt == null) {
        _connectedAt = DateTime.now();
        _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() {
            _callDuration = DateTime.now().difference(_connectedAt!);
          });
        });
      }
      if (state == CallState.kEnded) {
        _durationTimer?.cancel();
        Timer(const Duration(seconds: 2), () => widget.onClear?.call());
      }
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  void _answerCall() {
    setState(() => call.answer());
  }

  void _hangUp() {
    setState(() {
      if (call.isRinging) {
        call.reject();
      } else {
        call.hangup(reason: CallErrorCode.userHangup);
      }
    });
  }

  void _muteMic() {
    setState(() => call.setMicrophoneMuted(!call.isMicrophoneMuted));
  }

  void _muteCamera() {
    setState(() => call.setLocalVideoMuted(!call.isLocalVideoMuted));
  }

  String get _statusText {
    switch (_state) {
      case CallState.kRinging:
        return call.isOutgoing ? 'Ringing...' : 'Incoming call';
      case CallState.kInviteSent:
        return 'Calling...';
      case CallState.kCreateAnswer:
      case CallState.kConnecting:
        return 'Connecting...';
      case CallState.kConnected:
        return _formatDuration(_callDuration);
      case CallState.kEnded:
        return 'Call ended';
      default:
        return 'Setting up...';
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  Uri? get _avatarUrl {
    if (call.room.isDirectChat) {
      final other = call.room.unsafeGetUserFromMemoryOrFallback(
        call.room.directChatMatrixID ?? '',
      );
      return other.avatarUrl;
    }
    return call.room
        .getState(EventTypes.RoomAvatar)
        ?.content
        .tryGet<String>('url')
        ?.let((url) => Uri.tryParse(url));
  }

  @override
  Widget build(BuildContext context) {
    final isRinging = _state == CallState.kRinging && !call.isOutgoing;
    final hasVideo = !voiceonly && connected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hidden audio player to ensure remote audio works on web
          RemoteAudioPlayer(call: call),
          // Expanded video area
          if (_expanded && hasVideo) _buildVideoPanel(),
          // Compact control bar
          _buildControlBar(context, isRinging),
        ],
      ),
    );
  }

  Widget _buildVideoPanel() {
    final remoteStream = call.remoteUserMediaStream ??
        call.remoteScreenSharingStream;
    final localStream = call.localUserMediaStream;

    return Container(
      height: 280,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(color: Colors.white10, width: 1),
        ),
      ),
      child: Stack(
        children: [
          // Remote video (main view)
          if (remoteStream != null)
            Positioned.fill(
              child: VideoRenderer(
                remoteStream,
                mirror: false,
                fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
              ),
            )
          else
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FontAwesomeIcons.video, color: Colors.white30, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Waiting for video...',
                    style: TextStyle(color: Colors.white30, fontSize: 13),
                  ),
                ],
              ),
            ),
          // Local video (picture-in-picture)
          if (localStream != null && !isLocalVideoMuted)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                width: 120,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: VideoRenderer(
                  localStream,
                  mirror: true,
                  fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlBar(BuildContext context, bool isRinging) {
    final isEnded = _state == CallState.kEnded;
    final isConnected = _state == CallState.kConnected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isEnded
            ? const Color(0xFF2D2D2D)
            : isConnected
                ? const Color(0xFF1A3A1A) // Dark green like Discord
                : const Color(0xFF2D2D2D),
        border: Border(
          bottom: BorderSide(
            color: isConnected
                ? const Color(0xFF2D7D2D)
                : Colors.white10,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Status indicator dot
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected
                  ? const Color(0xFF43B581) // Discord green
                  : isEnded
                      ? Colors.red
                      : const Color(0xFFFAA61A), // Discord yellow
            ),
          ),
          // Call info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  voiceonly ? 'Voice Connected' : 'Video Call',
                  style: TextStyle(
                    color: isConnected
                        ? const Color(0xFF43B581)
                        : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$_statusText — $displayName',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Control buttons
          if (isRinging) ...[
            _ControlButton(
              icon: FontAwesomeIcons.phone,
              color: const Color(0xFF43B581),
              onTap: _answerCall,
              tooltip: 'Answer',
            ),
            const SizedBox(width: 4),
          ],
          if (isConnected) ...[
            _ControlButton(
              icon: isMicrophoneMuted
                  ? FontAwesomeIcons.microphoneSlash
                  : FontAwesomeIcons.microphone,
              color: isMicrophoneMuted ? Colors.red : Colors.white54,
              onTap: _muteMic,
              tooltip: isMicrophoneMuted ? 'Unmute' : 'Mute',
            ),
            if (!voiceonly) ...[
              const SizedBox(width: 4),
              _ControlButton(
                icon: isLocalVideoMuted
                    ? FontAwesomeIcons.videoSlash
                    : FontAwesomeIcons.video,
                color: isLocalVideoMuted ? Colors.red : Colors.white54,
                onTap: _muteCamera,
                tooltip: isLocalVideoMuted ? 'Turn on camera' : 'Turn off camera',
              ),
              const SizedBox(width: 4),
              _ControlButton(
                icon: _expanded
                    ? FontAwesomeIcons.chevronUp
                    : FontAwesomeIcons.chevronDown,
                color: Colors.white54,
                onTap: () => setState(() => _expanded = !_expanded),
                tooltip: _expanded ? 'Collapse' : 'Expand video',
              ),
            ],
            const SizedBox(width: 4),
          ],
          _ControlButton(
            icon: FontAwesomeIcons.phoneSlash,
            color: Colors.red,
            onTap: _hangUp,
            tooltip: 'Hang up',
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ControlButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.white.withOpacity(0.08),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
      ),
    );
  }
}

extension _StringLet on String {
  T let<T>(T Function(String) fn) => fn(this);
}
