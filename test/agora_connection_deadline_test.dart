import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/services/agora_voice_room_controller.dart';

class _SlowTokenController extends AgoraVoiceRoomController {
  @override
  Future<void> connect({
    required String channelId,
    required AgoraRoomRole role,
    bool previewCamera = false,
    bool preferBackendToken = false,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 35));
    throw StateError('Token service unavailable');
  }
}

void main() {
  testWidgets('RTC deadline does not interrupt pending token acquisition', (tester) async {
    final controller = _SlowTokenController();
    Object? failure;
    var finished = false;
    final connection = controller.ensureConnected(
      channelId: 'live_test', role: AgoraRoomRole.speaker,
    ).then<void>((_) { finished = true; }, onError: (Object error) {
      failure = error;
      finished = true;
    });
    await tester.pump(const Duration(seconds: 26));
    expect(finished, isFalse);
    await tester.pump(const Duration(seconds: 10));
    await connection;
    expect(failure, isA<StateError>());
    expect(failure.toString(), contains('Token service unavailable'));
    controller.dispose();
  });

  testWidgets('closing during token acquisition cancels the waiter', (tester) async {
    final controller = _SlowTokenController();
    Object? failure;
    final connection = controller.ensureConnected(
      channelId: 'live_test', role: AgoraRoomRole.speaker,
    ).then<void>((_) {}, onError: (Object error) { failure = error; });
    controller.dispose();
    await tester.pump();
    await connection;
    expect(failure.toString(), contains('Connection cancelled'));
    await tester.pump(const Duration(seconds: 36));
  });
}
