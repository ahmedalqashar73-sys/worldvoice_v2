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
}
