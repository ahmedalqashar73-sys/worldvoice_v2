import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

/// Recover only transient Firestore transport failures. Never retry a
/// permission/identity rejection, and never treat offline cache as proof of
/// room access or remaining quota.
abstract final class RoomFirestoreRecovery {
  static bool isTransient(Object error) =>
      error is TimeoutException ||
      (error is FirebaseException &&
          const <String>{
            'unavailable',
            'deadline-exceeded',
            'aborted',
          }.contains(error.code));

  static Future<T> retryRead<T>(
    Future<T> Function() read, {
    int attempts = 2,
    Duration timeout = const Duration(seconds: 12),
    Duration delay = const Duration(milliseconds: 750),
  }) async {
    if (attempts < 1) {
      throw ArgumentError.value(attempts, 'attempts');
    }
    for (var attempt = 1; attempt <= attempts; attempt++) {
      try {
        return await read().timeout(timeout);
      } catch (error) {
        if (attempt >= attempts || !isTransient(error)) rethrow;
        await Future<void>.delayed(delay);
      }
    }
    throw StateError('Unreachable Firestore retry state');
  }

  static String message(Object error, {required bool isArabic}) {
    if (isTransient(error)) {
      return isArabic
          ? 'تعذر الاتصال بقاعدة بيانات Firebase. تحقق من الإنترنت أو جرّب شبكة أخرى، ثم أعد الدخول إلى الغرفة.'
          : 'Cannot reach Firebase. Check your connection or try another network, then re-enter the room.';
    }
    if (error is FirebaseException && error.code == 'permission-denied') {
      return isArabic
          ? 'رفضت Firebase صلاحية دخول الغرفة. تأكد من تسجيل الدخول وصلاحيات الغرفة.'
          : 'Firebase denied room access. Check your sign-in and room permissions.';
    }
    if (error is FirebaseException && error.code == 'unauthenticated') {
      return isArabic
          ? 'انتهت جلسة تسجيل الدخول. سجّل الدخول مجددًا.'
          : 'Your sign-in expired. Please sign in again.';
    }
    return isArabic
        ? 'تعذر دخول الغرفة. حاول مرة أخرى، وإن استمرت المشكلة افحص سجلات التطبيق.'
        : 'Could not enter the room. Retry, or check app logs if it continues.';
  }
}
