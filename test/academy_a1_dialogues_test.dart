import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/data/academy_english_a1_dialogues.dart';
import 'package:worldvoice/features/learn/data/academy_english_a1_catalog.dart';
import 'package:worldvoice/features/learn/presentation/academy_english_a1_integrated_lesson.dart';

void main() {
  test('each of the 36 complete A1 lessons has distinct real conversation and listening', () {
    expect(EnglishA1DialogueCatalog.lessons.length, 3);
    final allDialogues = <String>{};
    final allListening = <String>{};
    for (var unit = 1; unit <= 3; unit++) {
      expect(EnglishA1DialogueCatalog.lessons[unit - 1], hasLength(12));
      for (var lesson = 1; lesson <= 12; lesson++) {
        final material = EnglishA1DialogueCatalog.forLesson(unit, lesson);
        expect(material.dialogue.contains(': '), isTrue);
        expect(material.dialogue.contains('\n'), isTrue);
        expect(material.dialogue.trim().length, greaterThan(50));
        expect(material.listening.trim().split(' ').length, greaterThanOrEqualTo(9));
        expect(allDialogues.add(material.dialogue), isTrue);
        expect(allListening.add(material.listening), isTrue);
      }
    }
    expect(allDialogues.length, 36);
    expect(allListening.length, 36);
  });

  testWidgets('lesson begins with an authored tutor conversation', (tester) async {
    final unit = EnglishA1Catalog.units.first;
    await tester.pumpWidget(MaterialApp(
      home: AcademyEnglishA1IntegratedLesson(
        unit: unit, lesson: unit.lessons.first, lessonNumber: 1,
      ),
    ));
    expect(find.text('Talk with your tutor'), findsOneWidget);
    expect(find.textContaining('Sara: Hello! My name is Sara.'), findsOneWidget);
    expect(find.byType(FilledButton), findsWidgets);
  });
}
