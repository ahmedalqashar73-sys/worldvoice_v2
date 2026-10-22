import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/live/services/live_startup_guard.dart';

void main() {
  test('Live startup step completes when an upstream service responds', () async {
    final value = await guardLiveStartup(
      Future.value('connected'),
      phase: 'Agora connection',
      timeout: const Duration(seconds: 1),
    );
    expect(value, 'connected');
  });

  test('Live startup returns a named timeout instead of spinning forever', () async {
    final never = Completer<void>();
    await expectLater(
      guardLiveStartup(
        never.future,
        phase: 'Firestore Live registration',
        timeout: const Duration(milliseconds: 30),
      ),
      throwsA(isA<TimeoutException>().having(
        (error) => error.message ?? '',
        'phase',
        contains('Firestore Live registration'),
      )),
    );
  });

  test('Live startup propagates permission and quota failures for retry', () async {
    await expectLater(
      guardLiveStartup<void>(
        Future<void>.error(StateError('PERMISSION_DENIED')),
        phase: 'hosting allowance',
        timeout: const Duration(seconds: 1),
      ),
      throwsA(isA<StateError>()),
    );
  });
}
