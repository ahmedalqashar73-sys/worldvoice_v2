import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/chat_bubble_catalog.dart';
import 'package:worldvoice/features/rooms/presentation/chat_bubble_frame.dart';

void main() {
  testWidgets('All fifteen original artworks can mount as message bubbles', (
    tester,
  ) async {
    for (final design in WorldVoiceChatBubbles.designs) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: WorldVoiceBubbleFrame(
                  design: design,
                  showSignature: true,
                  child: const Text(
                    'Hello! مرحبًا 🌸',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(SvgPicture),
        findsNWidgets(2),
        reason: 'Missing SVG bubble decoration: ${design.id}',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'Bubble artwork failed: ${design.id}',
      );
    }
  });
  testWidgets(
    'Compact jewelry stays fixed with RTL and enlarged multiline text',
    (tester) async {
      for (final direction in TextDirection.values) {
        for (final compact in [true, false]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Center(
                    child: MediaQuery(
                      data: const MediaQueryData(
                        textScaler: TextScaler.linear(2),
                      ),
                      child: Directionality(
                        textDirection: direction,
                        child: SizedBox(
                          width: 240,
                          child: WorldVoiceBubbleFrame(
                            design: WorldVoiceChatBubbles.designs.first,
                            compact: compact,
                            child: const Text(
                              'أهلاً بالجميع في WorldVoice. '
                              'A longer translated message wraps without stretching the artwork.',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final artSize = tester.getSize(find.byType(SvgPicture).first);
          expect(artSize.width, closeTo(720 * (compact ? .11 : .23), .01));
          expect(artSize.height, closeTo(260 * (compact ? .11 : .23), .01));
        }
      }
    },
  );
  testWidgets('Short compact messages stay content-sized', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Align(
      alignment: Alignment.topRight,
      child: WorldVoiceBubbleFrame(design: WorldVoiceChatBubbles.designs[2],
        compact: true, child: const Text('Hello', style: TextStyle(fontSize: 15))),
    ))));
    await tester.pumpAndSettle();
    final size = tester.getSize(find.byType(WorldVoiceBubbleFrame));
    expect(size.width, lessThan(110));
    expect(size.height, lessThan(45));
    expect(find.text('WorldVoice'), findsNothing);
    expect(tester.takeException(), isNull);
  });

}
