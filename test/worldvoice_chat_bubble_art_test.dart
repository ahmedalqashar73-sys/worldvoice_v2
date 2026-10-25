import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/chat_bubble_catalog.dart';
import 'package:worldvoice/features/rooms/presentation/chat_bubble_frame.dart';

void main() {
  testWidgets('All fifteen original artworks can mount as message bubbles',
      (tester) async {
    for (final design in WorldVoiceChatBubbles.designs) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Center(
          child: SizedBox(width: 280, child: WorldVoiceBubbleFrame(
            design: design, showSignature: true,
            child: const Text('Hello! مرحبًا 🌸',
              style: TextStyle(color: Colors.white)),
          )),
        )),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(SvgPicture), findsOneWidget,
        reason: 'Missing SVG bubble decoration: ${design.id}');
      expect(tester.takeException(), isNull,
        reason: 'Bubble artwork failed: ${design.id}');
    }
  });
}
