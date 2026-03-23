import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc_impl;
import 'package:matrix/matrix.dart';
import 'package:webrtc_interface/webrtc_interface.dart' hide Navigator;

import 'package:afterdamage/pages/chat_list/chat_list.dart';
import 'package:afterdamage/pages/dialer/dialer.dart';
import 'package:afterdamage/pages/dialer/group_call.dart';
import 'package:afterdamage/utils/platform_infos.dart';
import 'package:afterdamage/utils/voip/callkit_service.dart';
import '../../utils/voip/user_media_manager.dart';
import '../widgets/matrix.dart';

/// Holds the state of an active 1:1 call for the banner UI.
class ActiveCallState {
  final String callId;
  final CallSession call;
  final Client client;

  const ActiveCallState({
    required this.callId,
    required this.call,
    required this.client,
  });
}

class VoipPlugin with WidgetsBindingObserver implements WebRTCDelegate {
  final MatrixState matrix;
  Client get client => matrix.client;
  VoipPlugin(this.matrix) {
    voip = VoIP(client, this);
    if (!kIsWeb) {
      final wb = WidgetsBinding.instance;
      wb.addObserver(this);
      didChangeAppLifecycleState(wb.lifecycleState);
    }
  }
  bool background = false;
  bool speakerOn = false;
  late VoIP voip;
  OverlayEntry? overlayEntry;
  BuildContext get context => matrix.context;

  /// Notifier for the active 1:1 call. Used by the inline CallBanner on web.
  final ValueNotifier<ActiveCallState?> activeCallNotifier =
      ValueNotifier<ActiveCallState?>(null);

  void dispose() {
    if (!kIsWeb) {
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState? state) {
    background =
        (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused);
  }

  void addCallingOverlay(String callId, CallSession call) {
    // On web, use the inline CallBanner instead of a fullscreen overlay/dialog
    if (kIsWeb) {
      activeCallNotifier.value = ActiveCallState(
        callId: callId,
        call: call,
        client: client,
      );
      return;
    }

    final context = this.context;

    if (overlayEntry != null) {
      Logs().e('[VOIP] addCallingOverlay: The call session already exists?');
      overlayEntry!.remove();
    }
    overlayEntry = OverlayEntry(
      builder: (_) => Calling(
        context: context,
        client: client,
        callId: callId,
        call: call,
        onClear: () {
          overlayEntry?.remove();
          overlayEntry = null;
        },
      ),
    );
    Overlay.of(context).insert(overlayEntry!);
  }

  @override
  MediaDevices get mediaDevices => webrtc_impl.navigator.mediaDevices;

  @override
  bool get isWeb => kIsWeb;

  @override
  Future<RTCPeerConnection> createPeerConnection(
    Map<String, dynamic> configuration, [
    Map<String, dynamic> constraints = const {},
  ]) => webrtc_impl.createPeerConnection(configuration, constraints);

  Future<bool> get hasCallingAccount async => false;

  @override
  Future<void> playRingtone() async {
    if (!background && !await hasCallingAccount) {
      try {
        await UserMediaManager().startRingingTone();
      } catch (_) {}
    }
  }

  @override
  Future<void> stopRingtone() async {
    if (!background && !await hasCallingAccount) {
      try {
        await UserMediaManager().stopRingingTone();
      } catch (_) {}
    }
  }

  @override
  Future<void> handleNewCall(CallSession call) async {
    final callkit = CallkitService.instance;
    final callerName = call.room.getLocalizedDisplayname();
    final avatarUrl = call.room
        .getState(EventTypes.RoomAvatar)
        ?.content
        .tryGet<String>('url');
    final isVideo = call.type == CallType.kVideo;

    // Show native incoming/outgoing call screen on iOS/Android
    if (callkit.isSupported) {
      try {
        if (call.isOutgoing) {
          await callkit.showOutgoingCall(
            session: call,
            calleeName: callerName,
            avatarUrl: avatarUrl,
            isVideo: isVideo,
          );
        } else {
          await callkit.showIncomingCall(
            session: call,
            callerName: callerName,
            avatarUrl: avatarUrl,
            isVideo: isVideo,
          );
        }
      } catch (e) {
        Logs().w('[VOIP] CallKit failed, falling back to overlay: $e');
      }
    }

    if (PlatformInfos.isAndroid) {
      try {
        final wasForeground = await FlutterForegroundTask.isAppOnForeground;

        await matrix.store.setString(
          'wasForeground',
          wasForeground == true ? 'true' : 'false',
        );
        FlutterForegroundTask.setOnLockScreenVisibility(true);
        FlutterForegroundTask.wakeUpScreen();
        FlutterForegroundTask.launchApp();
      } catch (e) {
        Logs().e('VOIP foreground failed $e');
      }
    }

    // Always show the in-app overlay for the actual call UI
    addCallingOverlay(call.callId, call);
  }

  @override
  Future<void> handleCallEnded(CallSession session) async {
    // Dismiss native call screen
    try {
      await CallkitService.instance.endCall(session.callId);
    } catch (e) {
      Logs().w('[VOIP] CallKit endCall failed: $e');
    }

    // Clear the inline call banner on web
    if (kIsWeb) {
      // Small delay so the "Call ended" state is visible briefly
      Future.delayed(const Duration(seconds: 2), () {
        if (activeCallNotifier.value?.callId == session.callId) {
          activeCallNotifier.value = null;
        }
      });
    }

    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
      if (PlatformInfos.isAndroid) {
        FlutterForegroundTask.setOnLockScreenVisibility(false);
        FlutterForegroundTask.stopService();
        final wasForeground = matrix.store.getString('wasForeground');
        wasForeground == 'false' ? FlutterForegroundTask.minimizeApp() : null;
      }
    }
  }

  // ── Group Call State ──
  GroupCallSession? activeGroupCall;
  OverlayEntry? groupCallOverlayEntry;

  @override
  Future<void> handleGroupCallEnded(GroupCallSession groupCall) async {
    Logs().i('[VOIP] Group call ended: ${groupCall.groupCallId}');
    activeGroupCall = null;
    if (groupCallOverlayEntry != null) {
      groupCallOverlayEntry!.remove();
      groupCallOverlayEntry = null;
    }
  }

  @override
  Future<void> handleNewGroupCall(GroupCallSession groupCall) async {
    Logs().i('[VOIP] New group call: ${groupCall.groupCallId}');
    activeGroupCall = groupCall;

    final context = kIsWeb
        ? ChatList.contextForVoip!
        : this.context;

    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (context) => GroupCalling(
          context: context,
          client: client,
          groupCall: groupCall,
          onClear: () => Navigator.of(context).pop(),
        ),
      );
    } else {
      groupCallOverlayEntry = OverlayEntry(
        builder: (_) => GroupCalling(
          context: context,
          client: client,
          groupCall: groupCall,
          onClear: () {
            groupCallOverlayEntry?.remove();
            groupCallOverlayEntry = null;
          },
        ),
      );
      Overlay.of(context).insert(groupCallOverlayEntry!);
    }
  }

  @override
  // TODO: implement canHandleNewCall
  bool get canHandleNewCall =>
      voip.currentCID == null && voip.currentGroupCID == null;

  @override
  Future<void> handleMissedCall(CallSession session) async {
    Logs().i('[VOIP] Missed call from ${session.room.getLocalizedDisplayname()}');
    // Show a local notification for the missed call
    try {
      final flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      await flutterLocalNotificationsPlugin.show(
        id: session.callId.hashCode,
        title: 'Missed Call',
        body: 'Missed call from ${session.room.getLocalizedDisplayname()}',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'calls_channel',
            'Calls',
            channelDescription: 'Incoming and missed call notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      Logs().w('[VOIP] Failed to show missed call notification: $e');
    }
  }

  @override
  EncryptionKeyProvider? get keyProvider => null;

  @override
  Future<void> registerListeners(CallSession session) async {
    // Call state listeners are registered in the dialer UI (Calling widget).
    // No additional SDK-level listeners needed here.
  }
}
