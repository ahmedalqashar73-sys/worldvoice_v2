import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/core/localization/supported_language.dart';
import 'package:worldvoice/features/learn/data/course_catalog.dart';

void main() {
  test('beginner courses cover every supported app language', () {
    final supported = SupportedLanguages.all.map((language) => language.code).toSet();
    final offered = CourseCatalog.all.map((course) => course.code).toSet();
    expect(offered, supported);
    expect(CourseCatalog.all.length, 17);
  });

  test('each language offers real lesson content with speaking locale', () {
    for (final course in CourseCatalog.all) {
      expect(course.speechLocale, isNotEmpty, reason: course.code);
      expect(course.lessons.length, greaterThanOrEqualTo(2), reason: course.code);
      expect(course.wordCount, greaterThanOrEqualTo(10), reason: course.code);
      expect(course.lessons.map((lesson) => lesson.id).toSet().length,
          course.lessons.length, reason: course.code);
      for (final lesson in course.lessons) {
        expect(lesson.titleArabic, isNotEmpty);
        expect(lesson.titleEnglish, isNotEmpty);
        for (final word in lesson.words) {
          expect(word.text.trim(), isNotEmpty, reason: course.code);
          expect(word.pronunciation.trim(), isNotEmpty,
              reason: course.code + ': ' + word.text);
          expect(word.arabic.trim(), isNotEmpty, reason: course.code);
          expect(word.english.trim(), isNotEmpty, reason: course.code);
        }
      }
    }
  });

  test('different writing systems keep their authentic target spelling', () {
    expect(CourseCatalog.byCode('es')!.lessons.first.words.first.text, 'Hola');
    expect(CourseCatalog.byCode('zh')!.lessons.first.words.first.text, '你好');
    expect(CourseCatalog.byCode('ko')!.lessons.first.words.first.text, '안녕하세요');
    expect(CourseCatalog.byCode('ja')!.lessons.first.words.first.text, 'こんにちは');
    expect(CourseCatalog.byCode('ar')!.rightToLeft, isTrue);
    expect(CourseCatalog.byCode('fa')!.rightToLeft, isTrue);
    expect(CourseCatalog.byCode('ur')!.rightToLeft, isTrue);
    expect(CourseCatalog.byCode('es')!.speechLocale, 'es-ES');
    expect(CourseCatalog.byCode('zh')!.speechLocale, 'zh-CN');
  });
}
