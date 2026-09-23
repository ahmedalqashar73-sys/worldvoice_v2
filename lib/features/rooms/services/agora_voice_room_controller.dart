import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';

import '../data/agora_config.dart';

enum AgoraRoomRole { speaker, listener }

class AgoraVoiceRoomController extends ChangeNotifier {
  AgoraVoiceRoomController();

  RtcEngine? _engine;
  RtcEngineEventHandler? _handler;

  bool _connecting = false;
  bool _joined = false;
  bool _muted = false;
  bool _released = false;
  bool _screenSharing = false;
  String? _error;
  int? _localUid;
  int? _activeSpeakerUid;
  AgoraRoomRole _role = AgoraRoomRole.listener;
  final Set<int> _remoteSpeakers = <int>{};

  bool get connecting => _connecting;
  bool get joined => _joined;
  bool get muted => _muted;
  String? get error => _error;
  bool get screenSharing => _screenSharing;
  RtcEngine? get engine => _engine;
  int? get localUid => _localUid;
  int? get activeSpeakerUid => _activeSpeakerUid;
  AgoraRoomRole get role => _role;
  List<int> get remoteSpeakers => _remoteSpeakers.toList(growable: false);

  Future<void> connect({
    required String channelId,
    required AgoraRoomRole role,
  }) async {
    if (_connecting || _joined) return;

    if (!AgoraConfig.isConfigured) {
      _error =
          'Agora App ID is missing. Start Flutter with --dart-define=AGORA_APP_ID=YOUR_APP_ID';
      notifyListeners();
      return;
    }

    _connecting = true;
    _error = null;
    _role = role;
    notifyListeners();

    try {
      if (role == AgoraRoomRole.speaker) {
        final recorder = AudioRecorder();
        final allowed = await recorder.hasPermission();
        await recorder.dispose();
        if (!allowed) {
          throw StateError('Microphone permission was denied.');
        }
      }

      final engine = createAgoraRtcEngine();
      _engine = engine;

      await engine.initialize(
        const RtcEngineContext(
          appId: AgoraConfig.appId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      _handler = RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          _localUid = connection.localUid;
          _joined = true;
          _connecting = false;
          _error = null;
          notifyListeners();
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          _remoteSpeakers.add(remoteUid);
          notifyListeners();
        },
        onUserOffline: (connection, remoteUid, reason) {
          _remoteSpeakers.remove(remoteUid);
          notifyListeners();
        },
        onUserMuteAudio: (connection, remoteUid, muted) {
          notifyListeners();
        },
        onAudioVolumeIndication:
            (connection, speakers, speakerNumber, totalVolume) {
          int? loudestUid;
          var loudestVolume = 0;

          for (final speaker in speakers) {
            final volume = speaker.volume ?? 0;
            if (volume <= loudestVolume) continue;
            loudestVolume = volume;
            final rawUid = speaker.uid ?? 0;
            loudestUid = rawUid == 0 ? _localUid : rawUid;
          }

          final next = loudestVolume >= 18 ? loudestUid : null;
          if (next != _activeSpeakerUid) {
            _activeSpeakerUid = next;
            notifyListeners();
          }
        },
        onConnectionStateChanged: (connection, state, reason) {
          if (state == ConnectionStateType.connectionStateFailed) {
            _error = 'Agora connection failed: $reason';
            _connecting = false;
            notifyListeners();
          }
        },
        onError: (err, message) {
          _error = 'Agora error: $err $message';
          _connecting = false;
          notifyListeners();
        },
      );

      engine.registerEventHandler(_handler!);
      await engine.enableAudio();
      await engine.enableVideo();
      await engine.enableAudioVolumeIndication(
        interval: 200,
        smooth: 3,
        reportVad: true,
      );
      await engine.setAudioProfile(
        profile: AudioProfileType.audioProfileSpeechStandard,
      );

      final token = await _resolveToken(
        channelId: channelId,
        role: role,
      );

      await engine.joinChannel(
        token: token,
        channelId: channelId,
        uid: 0,
        options: ChannelMediaOptions(
          channelProfile:
              ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: role == AgoraRoomRole.speaker
              ? ClientRoleType.clientRoleBroadcaster
              : ClientRoleType.clientRoleAudience,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          publishCameraTrack: false,
          publishMicrophoneTrack: role == AgoraRoomRole.speaker,
          enableAudioRecordingOrPlayout: true,
        ),
      );
    } catch (error) {
      _error = error.toString();
      _connecting = false;
      notifyListeners();
      await leave();
    }
  }

  Future<String> _resolveToken({
    required String channelId,
    required AgoraRoomRole role,
  }) async {
    if (AgoraConfig.tokenEndpoint.trim().isEmpty) {
      return AgoraConfig.tempToken;
    }

    final response = await http.post(
      Uri.parse(AgoraConfig.tokenEndpoint),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'channelName': channelId,
        'uid': 0,
        'role': role == AgoraRoomRole.speaker ? 'publisher' : 'subscriber',
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Token server failed with HTTP ${response.statusCode}.',
      );
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw StateError('Token server returned an invalid response.');
    }

    final token = body['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw StateError('Token server did not return a token.');
    }

    return token;
  }

  Future<void> startScreenShare() async {
    final engine = _engine;
    if (engine == null || !_joined || _role != AgoraRoomRole.speaker) {
      return;
    }
    if (_screenSharing) return;

    await engine.startScreenCapture(
      const ScreenCaptureParameters2(
        captureAudio: true,
        captureVideo: true,
      ),
    );

    await engine.updateChannelMediaOptions(
      ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        publishCameraTrack: false,
        publishScreenCaptureVideo: true,
        publishScreenCaptureAudio: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        enableAudioRecordingOrPlayout: true,
      ),
    );

    _screenSharing = true;
    notifyListeners();
  }

  Future<void> stopScreenShare() async {
    final engine = _engine;
    if (engine == null || !_joined || !_screenSharing) return;

    await engine.stopScreenCapture();
    await engine.updateChannelMediaOptions(
      ChannelMediaOptions(
        clientRoleType: _role == AgoraRoomRole.speaker
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
        publishMicrophoneTrack: _role == AgoraRoomRole.speaker,
        publishCameraTrack: false,
        publishScreenCaptureVideo: false,
        publishScreenCaptureAudio: false,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        enableAudioRecordingOrPlayout: true,
      ),
    );

    _screenSharing = false;
    notifyListeners();
  }

  Future<void> setMuted(bool value) async {
    final engine = _engine;
    if (engine == null || !_joined || _role != AgoraRoomRole.speaker) {
      return;
    }

    await engine.muteLocalAudioStream(value);
    _muted = value;
    notifyListeners();
  }

  Future<void> switchRole(AgoraRoomRole role) async {
    final engine = _engine;
    if (engine == null || !_joined || role == _role) return;

    if (role == AgoraRoomRole.speaker) {
      final recorder = AudioRecorder();
      final allowed = await recorder.hasPermission();
      await recorder.dispose();
      if (!allowed) {
        _error = 'Microphone permission was denied.';
        notifyListeners();
        return;
      }
    }

    await engine.setClientRole(
      role: role == AgoraRoomRole.speaker
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
    );

    await engine.updateChannelMediaOptions(
      ChannelMediaOptions(
        clientRoleType: role == AgoraRoomRole.speaker
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
        publishMicrophoneTrack: role == AgoraRoomRole.speaker,
        publishCameraTrack: false,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        enableAudioRecordingOrPlayout: true,
      ),
    );

    _role = role;
    _muted = false;
    notifyListeners();
  }

  Future<void> leave() async {
    final engine = _engine;
    if (engine == null || _released) return;

    _released = true;
    try {
      if (_handler != null) {
        engine.unregisterEventHandler(_handler!);
      }
      await engine.leaveChannel();
      await engine.release();
    } finally {
      _engine = null;
      _handler = null;
      _joined = false;
      _connecting = false;
      _muted = false;
      _screenSharing = false;
      _localUid = null;
      _activeSpeakerUid = null;
      _remoteSpeakers.clear();
    }
  }

  @override
  void dispose() {
    if (!_released) {
      leave();
    }
    super.dispose();
  }
}
