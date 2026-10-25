import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/room_chat_message.dart';
import 'package:worldvoice/features/rooms/presentation/room_conversation_panel.dart';

void main() {
  testWidgets('Room translates an entire message, never just one word',
      (tester) async {
    final original =
        'Hello WorldVoice friends. We are learning Spanish together today.';
    String? translatedInput;
    final message = RoomChatMessage(
      id: 'message_1',
      userId: 'other_user',
      displayName: 'Learner',
      text: original,
      createdAt: DateTime(2026, 10, 25),
    );

    await tester.binding.setSurfaceSize(const Size(1000, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1000,
          height: 700,
          child: RoomConversationPanel(
            messages: Stream.value([message]),
            onSend: (_) async {},
            isArabic: false,
            onGifts: () {},
            onShop: () {},
            onTools: () {},
            onCaptions: () {},
            onMic: null,
            micIcon: Icons.mic,
            micLabel: 'Mic',
            onTranslateMessage: (wholeMessage) async {
              translatedInput = wholeMessage;
              return 'Hola amigos de WorldVoice. Hoy estudiamos español juntos.';
            },
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('learning Spanish'), findsOneWidget);
    await tester.tap(find.textContaining('learning Spanish'));
    await tester.pump();
    expect(translatedInput, original);
    await tester.pump();
    expect(find.textContaining('Hola amigos'), findsOneWidget);
  });
  testWidgets('CC is the only language action and translates while enabled', (tester) async {
    var opened = 0;
    var translated = false;
    await tester.binding.setSurfaceSize(const Size(728, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: RoomConversationPanel(
      messages: Stream.value([RoomChatMessage(id: 'cc-message', userId: 'other',
        displayName: 'Sara', text: 'Hello everyone', createdAt: DateTime(2026))]),
      onSend: (_) async {}, isArabic: false,
      onGifts: () {}, onShop: () {}, onTools: () {},
      onCaptions: () { opened++; }, onTranslation: () {},
      languageToolsEnabled: true,
      onMic: null, micIcon: Icons.mic, micLabel: 'Mic',
      onTranslateMessage: (text) async { translated = true; return 'مرحبًا بالجميع'; },
    ))));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.closed_caption_outlined), findsOneWidget);
    expect(find.byIcon(Icons.g_translate_rounded), findsNothing);
    expect(find.byIcon(Icons.translate_rounded), findsNothing);
    await tester.tap(find.byIcon(Icons.closed_caption_outlined));
    expect(opened, 1);
    expect(translated, isTrue);
    expect(find.text('مرحبًا بالجميع'), findsOneWidget);
  });

}
