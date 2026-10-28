import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worldvoice/core/ads/academy_lesson_ads.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('Three NEW free lessons per local day; fourth denied', () async {
    const uid = 'free-learner';
    final today = DateTime(2026, 10, 21, 13, 0);
    for (var i = 1; i <= 3; i++) {
      expect(
        await AcademyDailyLessonQuota.admit(uid, 'es.A1.u1.l$i', now: today),
        AcademyDailyAccess.newLesson,
      );
    }
    expect(
      await AcademyDailyLessonQuota.admit(uid, 'es.A1.u1.l4', now: today),
      AcademyDailyAccess.limitReached,
    );
    expect((await AcademyDailyLessonQuota.openedLessons(uid, now: today)).length,
        3);
  });

  test('Reopening a started lesson does not consume the daily allocation',
      () async {
    final today = DateTime(2026, 10, 21, 9, 0);
    const uid = 'free-learner';
    expect(await AcademyDailyLessonQuota.admit(uid, 'en.A1.l1', now: today),
        AcademyDailyAccess.newLesson);
    expect(await AcademyDailyLessonQuota.admit(uid, 'en.A1.l1', now: today),
        AcademyDailyAccess.alreadyStarted);
    expect(await AcademyDailyLessonQuota.admit(uid, 'es.B2.l7', now: today),
        AcademyDailyAccess.newLesson);
    expect(await AcademyDailyLessonQuota.admit(uid, 'es.C1.l9', now: today),
        AcademyDailyAccess.newLesson);
    expect(await AcademyDailyLessonQuota.admit(uid, 'en.A1.l1', now: today),
        AcademyDailyAccess.alreadyStarted);
    expect(await AcademyDailyLessonQuota.admit(uid, 'es.C2.l5', now: today),
        AcademyDailyAccess.limitReached);
  });

  test('Daily quota resets after midnight, not three days after first lesson',
      () async {
    const uid = 'student';
    final today = DateTime(2026, 10, 21, 23, 55);
    final tomorrow = DateTime(2026, 10, 22, 0, 1);
    for (var i = 1; i <= 3; i++) {
      expect(await AcademyDailyLessonQuota.admit(
          uid, 'spanish.A1.lesson$i', now: today),
        AcademyDailyAccess.newLesson);
    }
    expect(await AcademyDailyLessonQuota.admit(
        uid, 'spanish.A1.lesson4', now: today),
        AcademyDailyAccess.limitReached);
    expect(await AcademyDailyLessonQuota.admit(
        uid, 'spanish.A1.lesson4', now: tomorrow),
        AcademyDailyAccess.newLesson);
    expect(await AcademyDailyLessonQuota.openedLessons(uid, now: tomorrow),
      <String>['spanish.A1.lesson4']);
  });

  test('Different students and English/Spanish use isolated unified quota',
      () async {
    final today = DateTime(2026, 10, 21, 11);
    expect(await AcademyDailyLessonQuota.admit('alice', 'en.A1.1',
        now: today), AcademyDailyAccess.newLesson);
    expect(await AcademyDailyLessonQuota.admit('alice', 'es.A1.1',
        now: today), AcademyDailyAccess.newLesson);
    expect(await AcademyDailyLessonQuota.admit('alice', 'es.C2.5',
        now: today), AcademyDailyAccess.newLesson);
    expect(await AcademyDailyLessonQuota.admit('alice', 'en.B1.2',
        now: today), AcademyDailyAccess.limitReached);
    expect(await AcademyDailyLessonQuota.admit('bob', 'en.B1.2',
        now: today), AcademyDailyAccess.newLesson);
  });

  test('Concurrent taps do not allow more than three new lessons', () async {
    final day = DateTime(2026, 10, 21, 12);
    final entries = await Future.wait(List<Future<AcademyDailyAccess>>.generate(
      7, (i) => AcademyDailyLessonQuota.admit(
        'double-tap', 'lesson$i', now: day)));
    expect(entries.where((e) => e == AcademyDailyAccess.newLesson).length, 3);
    expect(entries.where((e) => e == AcademyDailyAccess.limitReached).length, 4);
  });

  test('Every new free lesson can request an interstitial without waiting a minute',
      () async {
    const student = 'rapid-learner';
    final now = DateTime(2026, 10, 21, 15);
    for (var index = 1; index <= 3; index++) {
      final result = await AcademyDailyLessonQuota.admit(
        student, 'es.A1.lesson$index', now: now);
      expect(result, AcademyDailyAccess.newLesson);
      // No one-minute cooldown on the deliberate lesson navigation boundary.
      expect(AcademyDemoAds.mayRequestLessonInterstitial, isTrue);
    }
    expect(await AcademyDailyLessonQuota.admit(student, 'es.A1.lesson4',
        now: now), AcademyDailyAccess.limitReached);
  });

  test('One app-open opportunity per three cold starts, separate from lessons',
      () async {
    const student = 'active-student';
    expect(await AcademyAppOpenFrequency.registerLaunch(student), false);
    expect(await AcademyAppOpenFrequency.registerLaunch(student), false);
    expect(await AcademyAppOpenFrequency.registerLaunch(student), true);
    expect(await AcademyAppOpenFrequency.registerLaunch(student), false);
    expect(await AcademyAppOpenFrequency.registerLaunch(student), false);
    expect(await AcademyAppOpenFrequency.registerLaunch(student), true);
  });

  test('App-open frequency keeps its own account scope', () async {
    expect(await AcademyAppOpenFrequency.registerLaunch('alice'), false);
    expect(await AcademyAppOpenFrequency.registerLaunch('alice'), false);
    expect(await AcademyAppOpenFrequency.registerLaunch('bob'), false);
    expect(await AcademyAppOpenFrequency.registerLaunch('alice'), true);
    expect(await AcademyAppOpenFrequency.registerLaunch('bob'), false);
    expect(await AcademyAppOpenFrequency.registerLaunch('bob'), true);
  });

  test('Empty user and lesson IDs are not admissible into daily quota',
      () async {
    await expectLater(
      AcademyDailyLessonQuota.admit('', 'es.A1.u1.l1'), throwsArgumentError);
    await expectLater(
      AcademyDailyLessonQuota.admit('u', ''), throwsArgumentError);
    expect(await AcademyAppOpenFrequency.registerLaunch(''), false);
  });
}
