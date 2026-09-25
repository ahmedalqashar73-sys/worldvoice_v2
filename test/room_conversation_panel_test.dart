import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/room_chat_message.dart';
import 'package:worldvoice/features/rooms/presentation/room_conversation_panel.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    for (final keyboard in [false, true]) {
      testWidgets('room chat fits width $width keyboard $keyboard', (tester) async {
        tester.view.physicalSize = Size(width, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final sent = <String>[];
        await tester.pumpWidget(MaterialApp(home: MediaQuery(
          data: MediaQueryData(size: Size(width, 740),
            textScaler: TextScaler.linear(width == 320 ? 1.6 : 1),
            viewInsets: EdgeInsets.only(bottom: keyboard ? 300 : 0)),
          child: Directionality(textDirection: TextDirection.rtl,
            child: Scaffold(body: RoomConversationPanel(
              messages: const Stream<List<RoomChatMessage>>.empty(),
              isArabic: true, onSend: (text) async { sent.add(text); },
              onGifts: () {}, onShop: () {}, onTools: () {},
              onCaptions: () {}, onMic: () {}, micIcon: Icons.mic, micLabel: 'مايك',
            ))))));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.enterText(find.byType(TextField), 'مرحبا');
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pump();
        expect(sent, ['مرحبا']);
        expect(find.text('مرحبا'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
