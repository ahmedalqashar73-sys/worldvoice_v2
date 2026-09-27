import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/room_chat_message.dart';
import 'package:worldvoice/features/rooms/presentation/room_conversation_panel.dart';
import 'package:worldvoice/features/rooms/presentation/room_keyboard_layout.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    for (final rtl in [false, true]) {
      testWidgets(
        'keyboard keeps room fixed and chat usable: $width RTL $rtl',
        (tester) async {
          tester.view.physicalSize = Size(width, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final sent = <String>[];
          const roomKey = ValueKey('room');

          Widget page(double keyboard) => MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 740),
                viewInsets: EdgeInsets.only(bottom: keyboard),
              ),
              child: Directionality(
                textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  body: RoomKeyboardLayout(
                    keyboardInset: keyboard,
                    room: const SizedBox(
                      key: roomKey,
                      height: 340,
                      child: Text('Seats / board / Teacher AI'),
                    ),
                    conversation: RoomConversationPanel(
                      messages: const Stream<List<RoomChatMessage>>.empty(),
                      isArabic: rtl,
                      onSend: (text) async {
                        sent.add(text);
                      },
                      onGifts: () {},
                      onShop: () {},
                      onTools: () {},
                      onCaptions: () {},
                      onMic: () {},
                      micIcon: Icons.mic,
                      micLabel: 'Mic',
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpWidget(page(0));
          final initialRoom = tester.getRect(find.byKey(roomKey));
          final roomElement = tester.element(find.byKey(roomKey));
          await tester.enterText(find.byType(TextField), 'hello');
          await tester.pumpWidget(page(300));
          await tester.pump();
          expect(tester.getRect(find.byKey(roomKey)), initialRoom);
          expect(tester.element(find.byKey(roomKey)), same(roomElement));
          expect(
            tester.getBottomLeft(find.byType(TextField)).dy,
            lessThanOrEqualTo(440),
          );
          expect(find.text('hello'), findsOneWidget);
          expect(
            tester
                .widget<EditableText>(find.byType(EditableText))
                .focusNode
                .hasFocus,
            isTrue,
          );
          await tester.tap(find.byTooltip(rtl ? 'إرسال' : 'Send'));
          await tester.pump();
          expect(sent, ['hello']);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(page(0));
          expect(tester.getRect(find.byKey(roomKey)), initialRoom);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
