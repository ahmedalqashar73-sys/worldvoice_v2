import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/presentation/podcast_sentence_translation.dart';

void main() {
  test('native language comes from profile code, including legacy profiles', () {
    expect(podcastNativeLanguageFromProfile({
      'nativeLanguageCode': 'es',
      'nativeLanguage': 'Arabic',
    }, 'en'), 'es');
    expect(podcastNativeLanguageFromProfile({
      'nativeLanguage': 'العربية',
    }, 'en'), 'ar');
    expect(podcastNativeLanguageFromProfile({
      'nativeLanguage': 'Español',
    }, 'ar'), 'es');
    expect(podcastNativeLanguageFromProfile({
      'nativeLanguage': 'Russian',
    }, 'en'), 'ru');
    expect(podcastNativeLanguageFromProfile(null, 'fr'), 'fr');
  });

  test('long text splits into isolated sentences before translating', () {
    expect(podcastReadingSentences('Hello. Welcome! How are you?'),
      ['Hello.', 'Welcome!', 'How are you?']);
    expect(podcastReadingSentences('Bonjour ! Bonsoir.'),
      ['Bonjour !', 'Bonsoir.']);
  });

  testWidgets('translation is opt-in per sentence, defaults to native language',
      (tester) async {
    final calls = <String>[];
    Future<String> translate(String text, String target) async {
      calls.add('$target|$text');
      return text == 'Hello there.' ? 'Hola.' : 'Bienvenido.';
    }
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            PodcastSentenceTranslation(
              key: const ValueKey('first-sentence'),
              text: 'Hello there.',
              nativeLanguageResolver: () async => 'es',
              translationOverride: translate,
            ),
            PodcastSentenceTranslation(
              key: const ValueKey('second-sentence'),
              text: 'Welcome.',
              nativeLanguageResolver: () async => 'es',
              translationOverride: translate,
            ),
          ],
        ),
      ),
    ));
    expect(find.byKey(const ValueKey('podcast-single-translation')),
        findsNothing);
    expect(calls, isEmpty);
    await tester.tap(find.byKey(const ValueKey('podcast-translate-sentence')).first);
    await tester.pumpAndSettle();
    expect(find.text('Hola.'), findsOneWidget);
    expect(find.text('Bienvenido.'), findsNothing);
    expect(calls, ['es|Hello there.']);
    await tester.tap(find.byKey(const ValueKey('podcast-translate-sentence')).first);
    await tester.pump();
    expect(find.text('Hola.'), findsNothing);
    expect(calls, hasLength(1));
    await tester.tap(find.byKey(const ValueKey('podcast-translate-sentence')).last);
    await tester.pumpAndSettle();
    expect(find.text('Bienvenido.'), findsOneWidget);
    expect(calls, ['es|Hello there.', 'es|Welcome.']);
  });

  testWidgets('publisher attribution is collapsed out of the player',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: PodcastSourceInfo(
          source: 'VOA Learning English',
          url: 'https://learningenglish.voanews.com/',
        ),
      ),
    ));
    expect(find.textContaining('VOA Learning English'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('podcast-source-details')));
    await tester.pumpAndSettle();
    expect(find.textContaining('VOA Learning English'), findsOneWidget);
  });
}
