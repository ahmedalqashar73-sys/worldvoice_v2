import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/services/agora_voice_room_controller.dart';

class _Engine extends Fake implements RtcEngine {
  bool capture = false;
  bool audioMuted = false;
  bool failOptions = false;
  bool failVideo = false;
  bool failPreview = false;
  final options = <ChannelMediaOptions>[];
  Completer<void>? cameraGate;

  @override
  Future<void> enableVideo() async {
    if (failVideo) throw StateError('camera failed');
    await cameraGate?.future;
  }
  @override
  Future<void> enableLocalVideo(bool enabled) async { capture = enabled; }
  @override
  Future<void> muteLocalVideoStream(bool muted) async {}
  @override
  Future<void> muteLocalAudioStream(bool muted) async { audioMuted = muted; }
  @override
  Future<void> updateChannelMediaOptions(ChannelMediaOptions value) async {
    if (failOptions) throw StateError('publication failed');
    options.add(value);
  }
  @override
  Future<void> startPreview({VideoSourceType sourceType = VideoSourceType.videoSourceCameraPrimary}) async {
    if (failPreview) throw StateError('preview failed');
  }
  @override
  Future<void> stopPreview({VideoSourceType sourceType = VideoSourceType.videoSourceCameraPrimary}) async {}
}

void main() {
  test('camera off/on preserves muted microphone and stops local capture', () async {
    final engine = _Engine();
    final controller = AgoraVoiceRoomController.forMediaTesting(engine);
    await controller.setMuted(true);
    await controller.setCameraPublishing(true);
    expect(engine.options.last.publishCameraTrack, true);
    expect(engine.options.last.publishMicrophoneTrack, false);
    await controller.setCameraPublishing(false);
    expect(engine.capture, false);
    expect(controller.cameraPublishing, false);
    await controller.setCameraPublishing(true);
    expect(controller.muted, true);
    expect(engine.audioMuted, true);
    expect(engine.options.last.publishMicrophoneTrack, false);
    await controller.setMuted(false);
    expect(controller.cameraPublishing, true);
    expect(engine.options.last.publishMicrophoneTrack, true);
    expect(engine.options.last.publishCameraTrack, isNull);
  });
  test('failed enable cleans capture and can retry without false success', () async {
    final engine = _Engine()..failOptions = true;
    final controller = AgoraVoiceRoomController.forMediaTesting(engine);
    await expectLater(controller.setCameraPublishing(true), throwsStateError);
    expect(controller.cameraPublishing, false);
    expect(engine.capture, false);
    engine.failOptions = false;
    await controller.setCameraPublishing(true);
    expect(controller.cameraPublishing, true);
  });
  test('rapid camera and microphone changes run in order', () async {
    final engine = _Engine()..cameraGate = Completer<void>();
    final controller = AgoraVoiceRoomController.forMediaTesting(engine);
    final camera = controller.setCameraPublishing(true);
    final mute = controller.setMuted(true);
    final stop = controller.setCameraPublishing(false);
    await Future<void>.delayed(Duration.zero);
    expect(engine.options, isEmpty);
    engine.cameraGate!.complete();
    await Future.wait([camera, mute, stop]);
    expect(controller.cameraPublishing, false);
    expect(controller.muted, true);
    expect(engine.options.last.publishMicrophoneTrack, false);
  });
  test('failed microphone update restores prior mute state', () async {
    final engine = _Engine()..failOptions = true;
    final controller = AgoraVoiceRoomController.forMediaTesting(engine);
    await expectLater(controller.setMuted(true), throwsStateError);
    expect(controller.muted, false);
    expect(engine.audioMuted, false);
  });
  test('failed guest preview keeps the existing Live audience connected', () async {
    final engine = _Engine()..failVideo = true;
    final controller = AgoraVoiceRoomController.forMediaTesting(engine);
    await expectLater(controller.prepareCameraPreview(), throwsStateError);
    expect(controller.joined, true);
    expect(controller.engine, same(engine));
    expect(controller.localPreviewPrepared, false);
    expect(controller.cameraPublishing, false);
    expect(engine.capture, false);

    engine.failVideo = false;
    await controller.prepareCameraPreview();
    expect(controller.localPreviewPrepared, true);
    await controller.stopCameraPreviewIfIdle();
    expect(controller.joined, true);
  });

  test('camera preview startup error does not drop a watching guest', () async {
    final engine = _Engine()..failPreview = true;
    final controller = AgoraVoiceRoomController.forMediaTesting(engine);
    await expectLater(controller.prepareCameraPreview(), throwsStateError);
    expect(controller.joined, true);
    expect(controller.engine, same(engine));
    expect(controller.localPreviewPrepared, false);
    engine.failPreview = false;
    await controller.prepareCameraPreview();
    expect(controller.localPreviewPrepared, true);
    expect(controller.joined, true);
  });

  test('consent camera preview stops without ending an Agora session', () async {
    final engine = _Engine();
    final controller = AgoraVoiceRoomController.forMediaTesting(engine);
    expect(controller.joined, true);
    await controller.prepareCameraPreview();
    expect(controller.localPreviewPrepared, true);
    await controller.stopCameraPreviewIfIdle();
    expect(controller.localPreviewPrepared, false);
    expect(controller.joined, true);
    expect(controller.cameraPublishing, false);
  });

  test('a publishing camera is not interrupted by preview cleanup', () async {
    final engine = _Engine();
    final controller = AgoraVoiceRoomController.forMediaTesting(engine);
    await controller.setCameraPublishing(true);
    await controller.stopCameraPreviewIfIdle();
    expect(controller.cameraPublishing, true);
    expect(controller.localPreviewPrepared, true);
  });

}
