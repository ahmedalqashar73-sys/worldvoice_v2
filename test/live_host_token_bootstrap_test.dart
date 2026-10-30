import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/live/services/live_session_service.dart';

void main() {
  test('host UID matches both Agora token issuer implementations', () async {
    expect(await LiveSessionService.hostAgoraUidForUser('test-user'),
        4166699045);
    expect(await LiveSessionService.hostAgoraUidForUser('firebase-uid-123'),
        649077852);
    expect(await LiveSessionService.hostAgoraUidForUser('abc'), 3128432319);
  });

  test('unauthenticated host cannot allocate a token identity', () async {
    await expectLater(
      LiveSessionService.hostAgoraUidForUser('  '),
      throwsStateError,
    );
  });

  test('pending host sessions are not shown as active Live', () {
    expect(
      LiveSessionService.isFresh({
        'isLive': true,
        'isReady': false,
      }),
      false,
    );
  });
}
