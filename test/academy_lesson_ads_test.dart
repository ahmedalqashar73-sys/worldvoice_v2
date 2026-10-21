import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worldvoice/core/ads/academy_lesson_ads.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('One interstitial opportunity every three free lesson openings', () async {
    const student = 'free-learner';
    expect(await AcademyAdFrequency.countFreeLessonVisit(student), false);
    expect(await AcademyAdFrequency.countFreeLessonVisit(student), false);
    expect(await AcademyAdFrequency.countFreeLessonVisit(student), true);
    expect(await AcademyAdFrequency.countFreeLessonVisit(student), false);
    expect(await AcademyAdFrequency.countFreeLessonVisit(student), false);
    expect(await AcademyAdFrequency.countFreeLessonVisit(student), true);
  });

  test('English and Spanish share one cadence, not a counter per stage', () async {
    const student = 'multi-language-learner';
    // These calls represent Spanish A1, English B2 and Spanish C1
    // lesson openings. Opening a story or vocabulary card never
    // invokes the visit counter from the unit's navigation.
    final spanishA1 = await AcademyAdFrequency.countFreeLessonVisit(student);
    final englishB2 = await AcademyAdFrequency.countFreeLessonVisit(student);
    final spanishC1 = await AcademyAdFrequency.countFreeLessonVisit(student);
    expect(<bool>[spanishA1, englishB2, spanishC1],
        <bool>[false, false, true]);
  });

  test('Frequency does not mix accounts and survives preference reads',
      () async {
    expect(await AcademyAdFrequency.countFreeLessonVisit('first'), false);
    expect(await AcademyAdFrequency.countFreeLessonVisit('first'), false);
    expect(await AcademyAdFrequency.countFreeLessonVisit('second'), false);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(AcademyAdFrequency.storageKey('first')), 2);
    expect(prefs.getInt(AcademyAdFrequency.storageKey('second')), 1);
    expect(await AcademyAdFrequency.countFreeLessonVisit('first'), true);
    expect(prefs.getInt(AcademyAdFrequency.storageKey('first')), 0);
    expect(prefs.getInt(AcademyAdFrequency.storageKey('second')), 1);
  });

  test('Anonymous students do not receive counted ad impressions',
      () async {
    expect(await AcademyAdFrequency.countFreeLessonVisit(''), false);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
  });
}
