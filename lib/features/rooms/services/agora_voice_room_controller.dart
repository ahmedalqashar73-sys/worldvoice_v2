import 'dart:async';
import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';

import '../data/agora_config.dart';
import '../data/room_backend_config.dart';

enum AgoraRoomRole { speaker, listener }

class AgoraVoiceRoomController extends ChangeNotifier {
  AgoraVoiceRoomController();

  RtcEngine? _engine;
  RtcEngineEventHandler? _handler;

  bool _connecting = false;
  bool _joined = false;
  bool _muted = false;
  bool _released = false;
  bool _disposed = false;
  int _connectionAttempt = 0;
  bool _screenSharing = false;
  bool _cameraPublishing = false;
  bool _localPreviewPrepared = false;
  bool _preparingLocalPreview = false;
  String? _error;
  int? _localUid;
  int? _activeSpeakerUid;
  AgoraRoomRole _role = AgoraRoomRole.listener;
  String? _channelId;
  bool _renewingToken = false;
  final Set<int> _remoteSpeakers = <int>{};

  bool get connecting => _connecting;
  bool get joined => _joined;
  bool get muted => _muted;
  String? get error => _error;
  bool get screenSharing => _screenSharing;
  bool get cameraPublishing => _cameraPublishing;
  bool get localPreviewPrepared => _localPreviewPrepared;
  RtcEngine? get engine => _engine;
  int? get localUid => _localUid;
  int? get activeSpeakerUid => _activeSpeakerUid;
  AgoraRoomRole get role => _role;
  List<int> get remoteSpeakers => _remoteSpeakers.toList(growable: false);

  /// Starts a local camera preview without waiting for a network token.
  /// Live uses this so the host sees the camera immediately while Agora
  /// authentication/join happens in the background.
  Future<void> prepareCameraPreview() async {
    if (_disposed || _preparingLocalPreview || _localPreviewPrepared) return;
    _preparingLocalPreview = true;
    _released = false;
    _error = null;

    try {
      var engine = _engine;
      if (engine == null) {
        engine = createAgoraRtcEngine();
        _engine = engine;
        await engine.initialize(
          const RtcEngineContext(
            appId: AgoraConfig.appId,
            channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          ),
        );
      }

      if (_disposed || _released || !identical(engine, _engine)) return;
      await engine.enableVideo();
      if (!_localPreviewPrepared) {
        await engine.startPreview();
        _localPreviewPrepared = true;
      }
      _error = null;
      notifyListeners();
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      await leave();
      rethrow;
    } finally {
      _preparingLocalPreview = false;
    }
  }

  /// Wait for Agora's join callback, not just the joinChannel request.
  Future<void> ensureConnected({
    required String channelId,
    required AgoraRoomRole role,
    bool previewCamera = false,
  }) async {
    if (_joined) return;
    final result = Completer<void>();
    void changed() {
      if (result.isCompleted) return;
      if (_joined) {
        result.complete();
      } else if (!_connecting && _error != null) {
        result.completeError(StateError(_error!));
      }
    }
    // Clear stale errors before observing a new connection attempt.
    if (!_connecting) _error = null;
    addListener(changed);
    Timer? timer;
    // Token acquisition has its own per-endpoint deadline. Start the RTC
    // deadline only after joinChannel has been submitted, so a cold backend
    // cannot consume the entire media connection budget.
    Future<void> begin() async {
      try {
        if (!_connecting) {
          await connect(channelId: channelId, role: role, previewCamera: previewCamera);
        }
        changed();
        if (!result.isCompleted) {
          timer = Timer(const Duration(seconds: 25), () {
            if (!result.isCompleted) {
              result.completeError(TimeoutException('Agora media connection timed out. Please retry.'));
            }
          });
        }
      } catch (error, stack) {
        if (!result.isCompleted) result.completeError(error, stack);
      }
    }
    unawaited(begin());
    try {
      await result.future;
    } catch (_) {
      await leave();
      rethrow;
    } finally {
      timer?.cancel();
      removeListener(changed);
    }
  }

  Future<void> connect({
    required String channelId,
    required AgoraRoomRole role,
    bool previewCamera = false,
  }) async {
    if (_disposed || _connecting || _joined) return;

    if (!AgoraConfig.isConfigured) {
      _error =
          'Agora App ID is missing. Start Flutter with --dart-define=AGORA_APP_ID=YOUR_APP_ID';
      notifyListeners();
      return;
    }

    // Reuse a local preview engine when Live prepared the camera before
    // requesting a token. A stale joined/failed engine is still released.
    if (_engine != null && _handler != null) await leave();
    if (_disposed) return;
    final attempt = ++_connectionAttempt;
    _released = false;
    _connecting = true;
    _channelId = channelId;
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

      if (_disposed || attempt != _connectionAttempt) return;
      var engine = _engine;
      if (engine == null) {
        engine = createAgoraRtcEngine();
        _engine = engine;
        await engine.initialize(
          const RtcEngineContext(
            appId: AgoraConfig.appId,
            channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          ),
        );
      }

      if (_disposed || attempt != _connectionAttempt) return;
      _handler = RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (_released) return;
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
          if (_released) return;
          if (state == ConnectionStateType.connectionStateFailed ||
              (state == ConnectionStateType.connectionStateDisconnected &&
                  _joined)) {
            // Preserve the room document and seats, but never pretend audio
            // is connected after Agora reports an offline transport.
            _joined = false;
            _connecting = false;
            _error ??= state == ConnectionStateType.connectionStateFailed
                ? 'Agora connection failed: $reason'
                : 'Audio transport disconnected: $reason. Retry your connection.';
            notifyListeners();
          } else if (state == ConnectionStateType.connectionStateConnected &&
              _localUid != null) {
            // Agora may automatically recover an existing voice session.
            _joined = true;
            _connecting = false;
            _error = null;
            notifyListeners();
          }
        },
        onTokenPrivilegeWillExpire: (connection, token) {
          unawaited(_renewToken());
        },
        onRequestToken: (connection) {
          unawaited(_renewToken());
        },
        onError: (err, message) {
          if (_released) return;
          _error = err == ErrorCodeType.errInvalidToken
              ? 'Agora rejected the token. Configure WORLDVOICE_ROOM_BACKEND_URL for this Agora project, or a valid AGORA_TEMP_TOKEN matching this channel: $channelId. App ID alone is not sufficient for a token-secured project.'
              : 'Agora error: $err $message';
          _connecting = false;
          notifyListeners();
        },
      );

      engine.registerEventHandler(_handler!);
      await engine.enableAudio();
      await engine.enableVideo();
      if (previewCamera &&
          role == AgoraRoomRole.speaker &&
          !_localPreviewPrepared) {
        await engine.startPreview();
        _localPreviewPrepared = true;
        notifyListeners();
      }
      await engine.enableAudioVolumeIndication(
        interval: 200,
        smooth: 3,
        reportVad: true,
      );
      await engine.setAudioProfile(
        profile: AudioProfileType.audioProfileSpeechStandard,
      );

      final credential = await _resolveCredential(
        channelId: channelId,
        role: role,
      );

      // A timed-out request or a user retry may release this engine while
      // an HTTPS token request is still pending. Never join a stale engine.
      if (_disposed || attempt != _connectionAttempt || _released || !identical(engine, _engine)) return;
      await engine.joinChannel(
        token: credential.token,
        channelId: channelId,
        uid: credential.uid,
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
      if (_disposed || attempt != _connectionAttempt) return;
      _error = error.toString();
      _connecting = false;
      notifyListeners();

      if (_localPreviewPrepared && !_joined && _engine != null) {
        final engine = _engine!;
        if (_handler != null) {
          try {
            engine.unregisterEventHandler(_handler!);
          } catch (_) {}
          _handler = null;
        }
        _channelId = null;
        try {
          await engine.enableVideo();
          await engine.startPreview();
        } catch (_) {
          await leave();
        }
      } else {
        await leave();
      }
    }
  }

  Future<({String token, int uid})> _resolveCredential({
    required String channelId,
    required AgoraRoomRole role,
  }) async {
    final endpoints = <String>[
      ...AgoraConfig.tokenEndpoints,
      if (RoomBackendConfig.configurationError.isEmpty)
        RoomBackendConfig.endpoint('/agora/token'),
    ].where((value) => value.trim().isNotEmpty).toSet().toList(growable: false);
    if (endpoints.isEmpty) {
      if (AgoraConfig.tempToken.trim().isNotEmpty) {
        return (token: AgoraConfig.tempToken, uid: 0);
      }
      throw StateError(RoomBackendConfig.configurationError.isNotEmpty
          ? RoomBackendConfig.configurationError
          : 'Agora token endpoint is missing.');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in is required before joining a voice room.');
    }

    final idToken = await user.getIdToken().timeout(const Duration(seconds: 15));
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Could not authorize the Agora token request.');
    }

    Object? lastError;
    for (final endpoint in endpoints) {
      final uri = Uri.tryParse(endpoint);
      if (uri == null || !uri.hasAuthority) continue;
      if (kReleaseMode && uri.scheme != 'https') continue;

      try {
        final response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $idToken',
              },
              body: jsonEncode({
                'channelName': channelId,
                'role':
                    role == AgoraRoomRole.speaker ? 'publisher' : 'subscriber',
              }),
            )
            .timeout(
              endpoint == AgoraConfig.stableTokenEndpoint
                  ? const Duration(seconds: 10)
                  : const Duration(seconds: 35),
            );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          String detail = '';
          try {
            final decoded = jsonDecode(response.body);
            if (decoded is Map<String, dynamic>) {
              detail = decoded['error']?.toString() ?? '';
            }
          } catch (_) {
            // Fall back to the HTTP status below.
          }
          throw StateError(
            detail.isEmpty
                ? 'Token server failed with HTTP ${response.statusCode}.'
                : detail,
          );
        }

        final body = jsonDecode(response.body);
        if (body is! Map<String, dynamic>) {
          throw StateError('Token server returned an invalid response.');
        }

        final token = body['token']?.toString() ?? '';
        final uid = (body['uid'] as num?)?.toInt() ?? 0;
        if (token.isEmpty || uid <= 0) {
          throw StateError('Token server did not return a valid token and UID.');
        }
        return (token: token, uid: uid);
      } on TimeoutException catch (error) {
        lastError = error;
      } catch (error) {
        lastError = error;
      }
    }

    throw StateError(
      'Agora token service is temporarily unavailable. '
      'Tried the fast token worker and the WorldVoice backend fallback. '
      '${lastError ?? ''}',
    );
  }

  Future<void> _renewToken({
    AgoraRoomRole? role,
  }) async {
    final engine = _engine;
    final channelId = _channelId;
    if (engine == null ||
        channelId == null ||
        !_joined ||
        _renewingToken ||
        AgoraConfig.tokenEndpoint.trim().isEmpty) {
      return;
    }

    _renewingToken = true;
    try {
      final credential = await _resolveCredential(
        channelId: channelId,
        role: role ?? _role,
      );

      final currentUid = _localUid;
      if (currentUid != null &&
          currentUid > 0 &&
          credential.uid != currentUid) {
        throw StateError('Token server returned a different Agora UID.');
      }

      await engine.renewToken(credential.token);
      _error = null;
    } catch (error) {
      _error = 'Agora token renewal failed: $error';
      notifyListeners();
    } finally {
      _renewingToken = false;
    }
  }

  Future<void> setCameraPublishing(bool value) async {
    final engine = _engine;
    if (engine == null || !_joined) return;
    if (value && _role != AgoraRoomRole.speaker) {
      throw StateError('Camera publishing requires broadcaster role.');
    }

    _cameraPublishing = value;
    if (value) {
      await engine.enableVideo();
      if (!_localPreviewPrepared) {
        await engine.startPreview();
        _localPreviewPrepared = true;
      }
    } else {
      if (_localPreviewPrepared) {
        try {
          await engine.stopPreview();
        } catch (_) {
          // Preview may already be stopped.
        }
      }
      _localPreviewPrepared = false;
    }

    if (!_screenSharing) {
      await engine.updateChannelMediaOptions(
        ChannelMediaOptions(
          clientRoleType: _role == AgoraRoomRole.speaker
              ? ClientRoleType.clientRoleBroadcaster
              : ClientRoleType.clientRoleAudience,
          publishMicrophoneTrack: _role == AgoraRoomRole.speaker,
          publishCameraTrack: value && _role == AgoraRoomRole.speaker,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          enableAudioRecordingOrPlayout: true,
        ),
      );
    }
    notifyListeners();
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

    // A local preview uses Agora's screen video track instead of a static
    // placeholder. Failure to preview must never interrupt publishing.
    try {
      await engine.startPreview(sourceType: VideoSourceType.videoSourceScreen);
    } catch (_) {
      // Sharing can still proceed; the remote participant renders the stream.
    }

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

    try {
      await engine.stopPreview(sourceType: VideoSourceType.videoSourceScreen);
    } catch (_) {
      // Cleanup is best effort even when the preview wasn't available.
    }
    await engine.stopScreenCapture();
    await engine.updateChannelMediaOptions(
      ChannelMediaOptions(
        clientRoleType: _role == AgoraRoomRole.speaker
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
        publishMicrophoneTrack: _role == AgoraRoomRole.speaker,
        publishCameraTrack:
            _role == AgoraRoomRole.speaker && _cameraPublishing,
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

  /// Live-only camera controls. These are additive and do not alter the
  /// existing Rooms camera/audio flow unless explicitly called.
  Future<void> setBeautyEnabled(bool enabled) =>
      setBeautyPreset(enabled ? 'natural' : 'off');

  Future<void> setBeautyPreset(String preset) async {
    final engine = _engine;
    final cameraActive =
        _localPreviewPrepared || (_joined && _cameraPublishing);
    if (engine == null || !cameraActive) {
      throw StateError('Camera preview must be active before beauty is changed.');
    }

    final normalized = preset.trim().toLowerCase();
    if (normalized == 'off') {
      await engine.setBeautyEffectOptions(
        enabled: false,
        options: BeautyOptions(),
      );
      return;
    }

    final options = switch (normalized) {
      'soft' => BeautyOptions(
          lighteningContrastLevel:
              LighteningContrastLevel.lighteningContrastNormal,
          lighteningLevel: 0.18,
          smoothnessLevel: 0.52,
          rednessLevel: 0.05,
          sharpnessLevel: 0.06,
        ),
      'bright' => BeautyOptions(
          lighteningContrastLevel:
              LighteningContrastLevel.lighteningContrastHigh,
          lighteningLevel: 0.38,
          smoothnessLevel: 0.28,
          rednessLevel: 0.05,
          sharpnessLevel: 0.14,
        ),
      'clean' => BeautyOptions(
          lighteningContrastLevel:
              LighteningContrastLevel.lighteningContrastNormal,
          lighteningLevel: 0.24,
          smoothnessLevel: 0.22,
          rednessLevel: 0.02,
          sharpnessLevel: 0.22,
        ),
      _ => BeautyOptions(
          lighteningContrastLevel:
              LighteningContrastLevel.lighteningContrastNormal,
          lighteningLevel: 0.22,
          smoothnessLevel: 0.32,
          rednessLevel: 0.06,
          sharpnessLevel: 0.12,
        ),
    };

    await engine.setBeautyEffectOptions(
      enabled: true,
      options: options,
    );
  }

  Future<bool> isBeautyAvailable() async {
    final engine = _engine;
    if (engine == null) return false;
    try {
      return await engine.isFeatureAvailableOnDevice(
        FeatureType.videoBeautyEffect,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> isVirtualBackgroundAvailable() async {
    final engine = _engine;
    if (engine == null) return false;
    try {
      return await engine.isFeatureAvailableOnDevice(
        FeatureType.videoVirtualBackground,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> setBackgroundBlurEnabled(bool enabled) async {
    final engine = _engine;
    final cameraActive =
        _localPreviewPrepared || (_joined && _cameraPublishing);
    if (engine == null || !cameraActive) {
      throw StateError(
        'Camera preview must be active before background blur is changed.',
      );
    }
    if (enabled && !await isVirtualBackgroundAvailable()) {
      throw StateError('Virtual background is not supported on this device.');
    }
    await engine.enableVirtualBackground(
      enabled: enabled,
      backgroundSource: VirtualBackgroundSource(
        backgroundSourceType: BackgroundSourceType.backgroundBlur,
        blurDegree: BackgroundBlurDegree.blurDegreeMedium,
      ),
      segproperty: const SegmentationProperty(
        modelType: SegModelType.segModelAi,
      ),
    );
  }

  Future<double> getCameraMaxZoom() async {
    final engine = _engine;
    final cameraActive =
        _localPreviewPrepared || (_joined && _cameraPublishing);
    if (engine == null || !cameraActive) return 1;
    try {
      final value = await engine.getCameraMaxZoomFactor();
      if (!value.isFinite || value < 1) return 1;
      // Keep the Live UI practical even on devices reporting huge ranges.
      return value.clamp(1.0, 8.0).toDouble();
    } catch (_) {
      return 1;
    }
  }

  Future<void> setCameraZoom(double factor) async {
    final engine = _engine;
    final cameraActive =
        _localPreviewPrepared || (_joined && _cameraPublishing);
    if (engine == null || !cameraActive) return;
    final max = await getCameraMaxZoom();
    await engine.setCameraZoomFactor(factor.clamp(1.0, max).toDouble());
  }

  Future<void> switchCamera() async {
    final engine = _engine;
    if (engine == null) return;
    await engine.switchCamera();
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

    if (AgoraConfig.tokenEndpoint.trim().isNotEmpty) {
      await _renewToken(role: role);
      if (role == AgoraRoomRole.speaker && _error != null) {
        // A member must never claim a working microphone before receiving
        // the publisher privilege for the same channel and UID.
        throw StateError(_error!);
      }
    }

    if (role == AgoraRoomRole.listener && _cameraPublishing) {
      if (_localPreviewPrepared) {
        try {
          await engine.stopPreview();
        } catch (_) {
          // Preview may already be stopped.
        }
      }
      _cameraPublishing = false;
      _localPreviewPrepared = false;
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
    _connectionAttempt++;
    final engine = _engine;
    if (engine == null || _released) return;

    _released = true;
    try {
      if (_handler != null) {
        engine.unregisterEventHandler(_handler!);
      }
      if (_localPreviewPrepared) {
        try {
          await engine.stopPreview();
        } catch (_) {
          // The camera session may already be closing.
        }
      }
      if (_joined) {
        await engine.leaveChannel();
      }
      await engine.release();
    } finally {
      _engine = null;
      _handler = null;
      _joined = false;
      _connecting = false;
      _muted = false;
      _screenSharing = false;
      _cameraPublishing = false;
      _localPreviewPrepared = false;
      _preparingLocalPreview = false;
      _localUid = null;
      _activeSpeakerUid = null;
      _channelId = null;
      _renewingToken = false;
      _remoteSpeakers.clear();
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _connecting = false;
    _error = 'Connection cancelled.';
    notifyListeners();
    _disposed = true;
    if (!_released) {
      leave();
    }
    super.dispose();
  }
}
