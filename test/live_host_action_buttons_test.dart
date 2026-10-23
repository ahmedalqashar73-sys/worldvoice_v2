import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/live/presentation/live_priority_controls.dart';

void main() {
  testWidgets('all four host Live actions receive taps above camera surface',
      (tester) async {
    var cameraTaps = 0;
    var chat = 0;
    var board = 0;
    var guests = 0;
    var gifts = 0;

    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        // Simulates an opaque, full-screen Agora video surface.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => cameraTaps++,
          child: const ColoredBox(color: Colors.black),
        ),
        Positioned(
          bottom: 10, left: 0, right: 0,
          child: Material(
            color: const Color(0xFF124533),
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: LiveHostActionButtons(
                  ar: true,
                  onChat: () => chat++,
                  onBoard: () => board++,
                  onRequests: () => guests++,
                  onGifts: () => gifts++,
                ),
              ),
            ),
          ),
        ),
      ]),
    )));

    await tester.tap(find.byKey(const ValueKey('live-host-chat')));
    await tester.tap(find.byKey(const ValueKey('live-host-whiteboard')));
    await tester.tap(find.byKey(const ValueKey('live-host-requests')));
    await tester.tap(find.byKey(const ValueKey('live-host-gifts')));
    await tester.pump();

    expect(chat, 1);
    expect(board, 1);
    expect(guests, 1);
    expect(gifts, 1);
    expect(cameraTaps, 0);
  });
}
