import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/chat/presentation/chat_media_bubble.dart';

void main() {
  testWidgets('private voice notes display playback, duration and waveform',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: WorldVoiceVoiceMessageBubble(
          localPath: '/tmp/worldvoice-test-note.m4a',
        ),
      ),
    ));
    expect(find.byKey(const ValueKey('worldvoice-voice-play')), findsOneWidget);
    expect(find.byKey(const ValueKey('worldvoice-voice-waveform')),
        findsOneWidget);
    expect(find.text('Voice message'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.textContaining('.m4a'), findsNothing);
    expect(find.byIcon(Icons.picture_as_pdf_rounded), findsNothing);
  });

  testWidgets('delivered voice notes never display the audio filename',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ChatMediaBubble(
          type: 'audio',
          url: 'https://example.test/clip.m4a',
          cacheScope: 'chat_test',
          fileName: 'wv_voice_17937004147.m4a',
        ),
      ),
    ));
    expect(find.text('Voice message'), findsOneWidget);
    expect(find.byKey(const ValueKey('worldvoice-voice-waveform')),
        findsOneWidget);
    expect(find.textContaining('wv_voice_'), findsNothing);
    expect(find.byIcon(Icons.picture_as_pdf_rounded), findsNothing);
  });
}
