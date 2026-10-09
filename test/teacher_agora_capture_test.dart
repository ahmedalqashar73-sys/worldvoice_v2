import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/services/agora_voice_room_controller.dart';
import 'package:worldvoice/features/rooms/services/room_caption_service.dart';
import 'package:worldvoice/features/rooms/services/room_live_caption_controller.dart';

class _Transcriber extends RoomCaptionService {
  _Transcriber() : super(roomId: 'test');
  int calls = 0;
  @override
  Future<String> transcribeWav(Uint8List bytes, {String? languageCode}) async {
    expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
    expect(languageCode, 'en');
    calls++;
    return 'Hello teacher';
  }
}

void main() {
  test('Agora phrases reach conversation and playback audio is ignored', () async {
    final frames = StreamController<AgoraRoomAudioFrame>(sync: true);
    final service = _Transcriber();
    final words = <String>[];
    final controller = RoomLiveCaptionController(
      service: service, audioFrames: frames.stream,
      onState: ({required bool listening, String? error}) {},
      onTranscript: ({required String text, required bool isLocal,
        required String languageCode, int? agoraUid}) { words.add(text); },
    );
    await controller.configure(enabled: true, canPublish: true,
      languageCode: 'en', displayName: 'Test', useAgoraLocal: true);
    void phrase() {
      for (var i = 0; i < 20; i++) {
        final data = ByteData(3200);
        if (i < 10) {
          for (var j = 0; j < 3200; j += 2) {
            data.setInt16(j, 1500, Endian.little);
          }
        }
        frames.add(AgoraRoomAudioFrame(bytes: data.buffer.asUint8List(),
          sampleRate: 16000, channels: 1, isLocal: true));
      }
    }
    phrase();
    await Future<void>.delayed(Duration.zero);
    expect(words, ['Hello teacher']);
    controller.pauseForPlayback(true);
    phrase();
    await Future<void>.delayed(Duration.zero);
    expect(service.calls, 1);
    controller.pauseForPlayback(false);
    phrase();
    await Future<void>.delayed(Duration.zero);
    expect(words, ['Hello teacher', 'Hello teacher']);
    await controller.configure(enabled: false, canPublish: false,
      languageCode: 'en', displayName: 'Test', useAgoraLocal: true);
    phrase();
    expect(service.calls, 2);
    await controller.dispose();
    await frames.close();
  });
}
