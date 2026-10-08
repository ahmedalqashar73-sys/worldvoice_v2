import 'dart:async';

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
        await tester.tap(find.byKey(
          const ValueKey<String>('worldvoice-room-chat-input'),
        ));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNWidgets(2));
        await tester.enterText(find.byType(TextField).last, 'مرحبا');
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pumpAndSettle();
        expect(sent, ['مرحبا']);
        expect(find.text('مرحبا'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('only newly arriving room message gets bubble animation', (tester) async {
    final updates = StreamController<List<RoomChatMessage>>();
    addTearDown(updates.close);
    RoomChatMessage message(String id) => RoomChatMessage(
      id: id, userId: 'u1', displayName: 'Ahmed', text: id, createdAt: null,
    );
    final original = message('first-message');
    final newest = message('new-message');

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RoomConversationPanel(
          messages: updates.stream,
          isArabic: false,
          onSend: (_) async {},
          onGifts: () {},
          onShop: () {},
          onTools: () {},
          onCaptions: () {},
          onMic: () {},
          micIcon: Icons.mic,
          micLabel: 'Mic',
        ),
      ),
    ));

    updates.add([original]);
    await tester.pump();
    expect(find.textContaining('first-message'), findsOneWidget);
    expect(find.byKey(const ValueKey('new-message-first-message')), findsNothing);

    updates.add([newest, original]);
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('new-message'), findsOneWidget);
    expect(find.byKey(const ValueKey('new-message-new-message')), findsOneWidget);
    expect(find.byKey(const ValueKey('new-message-first-message')), findsNothing);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
  testWidgets('keyboard docks composer without shifting room stage', (tester) async {
    final inset = ValueNotifier<double>(0);
    addTearDown(inset.dispose);
    await tester.pumpWidget(MaterialApp(
      home: ValueListenableBuilder<double>(
        valueListenable: inset,
        builder: (context, keyboardHeight, _) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            viewInsets: EdgeInsets.only(bottom: keyboardHeight),
          ),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: Column(children: [
              const SizedBox(
                key: ValueKey('fixed-room-stage'),
                height: 240,
                width: double.infinity,
              ),
              Expanded(child: RoomConversationPanel(
                messages: const Stream<List<RoomChatMessage>>.empty(),
                isArabic: true,
                onSend: (_) async {},
                onGifts: () {},
                onShop: () {},
                onTools: () {},
                onCaptions: () {},
                onMic: () {},
                micIcon: Icons.mic,
                micLabel: 'مايك',
              )),
            ]),
          ),
        ),
      ),
    ));
    final stage = find.byKey(const ValueKey('fixed-room-stage'));
    final beforeStage = tester.getRect(stage);
    final field = find.byKey(
      const ValueKey<String>('worldvoice-room-chat-input'),
    );
    final beforeField = tester.getRect(field);
    inset.value = 300;
    await tester.pump();
    expect(tester.getRect(stage), beforeStage);
    expect(tester.getRect(field), beforeField);
    expect(tester.takeException(), isNull);
  });

}
