import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/presentation/b1_voa_transcript_section.dart';
import 'package:worldvoice/features/learn/presentation/podcast_sentence_translation.dart';

Map<String, dynamic> draftFixture() {
  return {
    'id': 'en-b1-voa-001',
    'audio_url': 'https://voa-audio.voanews.eu/vle/2025/03/02/20250302-003003-vle122-program.mp3?download=1',
    'level': 'B1',
    'measured_duration_ms': 1800000,
    'transcript_status': 'machine_draft_review_required',
    'translation_status': 'machine_draft_review_required',
    'sync_status': 'unverified',
    'approved_for_publication': false,
    'dialogue': [
      for (var i = 0; i < 25; i++)
        {
          'start_ms': i * 3000,
          'end_ms': i * 3000 + 2900,
          'text': 'English line number $i',
          'translation_ar': 'السطر العربي رقم $i',
        },
    ],
  };
}

void main() {
  test('all 30 original B1 recordings have cached bilingual assets', () async {
    final ids = await const B1VoaTranscriptRepository().availableIds();
    expect(ids, hasLength(30));
    expect(ids.contains('en-b1-voa-001'), isTrue);
    expect(ids.contains('en-b1-voa-030'), isTrue);
  });

  test('B1 bilingual draft requires measured audio and nonempty translations',
      () {
    final first = B1VoaTranscript.fromJson(draftFixture());
    expect(first.lines, hasLength(25));
    expect(first.isMachineDraft, isTrue);
    expect(first.indexAt(const Duration(milliseconds: 3000)), 1);
    expect(first.indexAt(const Duration(milliseconds: 15000)), 5);
    expect(first.indexAt(const Duration(milliseconds: 300000)), -1);
    final emptyArabic = draftFixture();
    (emptyArabic['dialogue'] as List<dynamic>)[0]['translation_ar'] = '';
    expect(() => B1VoaTranscript.fromJson(emptyArabic),
        throwsFormatException);
    final wrongStatus = draftFixture();
    wrongStatus['sync_status'] = 'verified';
    expect(() => B1VoaTranscript.fromJson(wrongStatus),
        throwsFormatException);
  });

  testWidgets('B1 transcript shows English with opt-in per-sentence translator',
      (tester) async {
    final captions = B1VoaTranscript.fromJson(draftFixture());
    Duration? seeked;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: B1VoaCaptionPanel(
          transcript: captions,
          position: const Duration(seconds: 3),
          onSeek: (v) => seeked = v,
        ),
      )),
    ));
    expect(find.text('English line number 1'), findsWidgets);
    expect(find.text('السطر العربي رقم 1'), findsNothing);
    expect(find.byKey(const ValueKey('podcast-translate-sentence')), findsWidgets);
    expect(find.byKey(const ValueKey('b1-bilingual-captions')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('b1-caption-line-0')));
    expect(seeked, Duration.zero);
  });
  testWidgets('B1 long original captions show every word without ellipsis',
      (tester) async {
    final fixture = draftFixture();
    final dialogue = fixture['dialogue'] as List<dynamic>;
    const fullEnglish =
        'This is a complete long listening transcript. '
        'Every sentence must remain readable while the original audio plays. '
        'The listener can read the entire English passage without clipping, '
        'including additional words at the end of the original paragraph.';
    const fullArabic =
        'هذه ترجمة عربية طويلة يجب عرضها كاملة دون حذف الكلمات أو إخفاء النهاية '
        'حتى يستطيع الطالب متابعة كل ما قيل في الحلقة الصوتية الأصلية.';
    (dialogue[0] as Map<String, dynamic>)['text'] = fullEnglish;
    (dialogue[0] as Map<String, dynamic>)['translation_ar'] = fullArabic;
    final transcript = B1VoaTranscript.fromJson(fixture);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: B1VoaCaptionPanel(
            transcript: transcript,
            position: Duration.zero,
            onSeek: (_) {},
          ),
        ),
      ),
    ));
    final firstRow = find.byKey(const ValueKey('b1-caption-line-0'));
    final englishText = tester.widget<Text>(
      find.descendant(of: firstRow, matching: find.text(fullEnglish)),
    );
    final translate = tester.widget<PodcastSentenceTranslation>(
      find.descendant(
        of: firstRow,
        matching: find.byType(PodcastSentenceTranslation),
      ),
    );
    expect(englishText.maxLines, isNull);
    expect(englishText.overflow, isNull);
    expect(find.text(fullArabic), findsNothing);
    expect(translate.arabicDraft, fullArabic);
  });

}
