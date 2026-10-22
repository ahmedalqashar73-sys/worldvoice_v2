import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/live/presentation/live_priority_controls.dart';

void main() {
  testWidgets('top-most Live controls receive taps above fullscreen video overlay',
      (tester) async {
    var backgroundTaps = 0;
    var menuTaps = 0;
    var languageTaps = 0;
    var endTaps = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(fit: StackFit.expand, children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => backgroundTaps++,
              child: const ColoredBox(color: Colors.black),
            ),
          ),
          PositionedDirectional(
            top: 64,
            start: 12,
            child: LivePriorityMenuButtons(
              ar: true,
              onLanguage: () => languageTaps++,
              onOptions: () => menuTaps++,
            ),
          ),
          PositionedDirectional(
            top: 12,
            end: 12,
            child: LivePriorityExitButton(
              ar: true,
              host: true,
              onExit: () => endTaps++,
            ),
          ),
        ]),
      ),
    ));

    await tester.tap(find.byKey(const ValueKey('live-priority-options')));
    await tester.tap(find.byKey(const ValueKey('live-priority-language')));
    await tester.tap(find.byKey(const ValueKey('live-priority-exit')));
    await tester.pump();

    expect(menuTaps, 1);
    expect(languageTaps, 1);
    expect(endTaps, 1);
    expect(backgroundTaps, 0);
  });
}
