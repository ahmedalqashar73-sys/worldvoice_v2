import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/services/room_firestore_recovery.dart';

void main() {
  FirebaseException failure(String code) =>
      FirebaseException(plugin: 'cloud_firestore', code: code);

  test('retries a transient offline Firestore document read once', () async {
    var reads = 0;
    final value = await RoomFirestoreRecovery.retryRead<int>(
      () async {
        reads++;
        if (reads == 1) throw failure('unavailable');
        return 42;
      },
      delay: Duration.zero,
    );
    expect(value, 42);
    expect(reads, 2);
  });

  test('refuses to retry a permission failure or allow stale quota', () async {
    var reads = 0;
    await expectLater(
      RoomFirestoreRecovery.retryRead<int>(
        () async {
          reads++;
          throw failure('permission-denied');
        },
        delay: Duration.zero,
      ),
      throwsA(isA<FirebaseException>()),
    );
    expect(reads, 1);
  });

  test('persistent offline failure remains a failure after bounded retry', () async {
    var reads = 0;
    await expectLater(
      RoomFirestoreRecovery.retryRead<int>(
        () async {
          reads++;
          throw failure('unavailable');
        },
        delay: Duration.zero,
      ),
      throwsA(isA<FirebaseException>()),
    );
    expect(reads, 2);
  });

  test('a slow read is bounded and retried without granting room access', () async {
    var reads = 0;
    await expectLater(
      RoomFirestoreRecovery.retryRead<int>(
        () {
          reads++;
          return Completer<int>().future;
        },
        timeout: const Duration(milliseconds: 1),
        delay: Duration.zero,
      ),
      throwsA(isA<TimeoutException>()),
    );
    expect(reads, 2);
  });

  test('Arabic offline message is actionable and never exposes raw SDK errors', () {
    final message = RoomFirestoreRecovery.message(
      failure('unavailable'), isArabic: true);
    expect(message, contains('Firebase'));
    expect(message, contains('الإنترنت'));
    expect(message, isNot(contains('cloud_firestore/unavailable')));
  });

  test('permission failures have their own explanation', () {
    expect(
      RoomFirestoreRecovery.message(
        failure('permission-denied'), isArabic: true),
      contains('صلاحية'),
    );
  });
}
