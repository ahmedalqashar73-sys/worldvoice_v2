import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/live/presentation/live_screen.dart';

Widget _camera(String id) => SizedBox.expand(
  key: ValueKey('live-camera-$id'),
  child: const ColoredBox(color: Colors.black),
);

Future<void> _render(
  WidgetTester tester,
  List<String> ids, {
  bool compact = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 340,
            height: compact ? 110 : 600,
            child: WorldVoiceLiveVideoGrid(
              compact: compact,
              children: ids.map(_camera).toList(),
            ),
          ),
        ),
      ),
    ),
  );
}

Rect _cameraRect(WidgetTester tester, String id) =>
    tester.getRect(find.byKey(ValueKey('live-camera-$id')));

void main() {
  testWidgets('approved solo video occupies the tall rounded camera card',
      (tester) async {
    await _render(tester, ['host']);
    final host = _cameraRect(tester, 'host');
    expect(host.height, greaterThan(550));
    expect(host.width, greaterThan(300));
    expect(find.byType(WorldVoiceLiveVideoGrid), findsOneWidget);
  });

  testWidgets('a single camera has no extra inset tile or spacer', (tester) async {
    await _render(tester, ['host']);
    final rect = _cameraRect(tester, 'host');
    expect(rect.width, 340);
    expect(rect.height, 600);
  });

  testWidgets('approved host + 1 guest uses adjacent portrait cameras',
      (tester) async {
    await _render(tester, ['host', 'guest']);
    final host = _cameraRect(tester, 'host');
    final guest = _cameraRect(tester, 'guest');
    expect(guest.left, greaterThan(host.right));
    expect((host.top - guest.top).abs(), lessThan(2));
    expect((host.width - guest.width).abs(), lessThan(2));
    expect((host.height - guest.height).abs(), lessThan(2));
    expect(host.width, greaterThan(140));
    expect(host.height, greaterThan(550));
  });

  testWidgets('host with two guests has a full-height right camera like the reference',
      (tester) async {
    await _render(tester, ['host', 'a', 'b']);
    final host = _cameraRect(tester, 'host');
    final a = _cameraRect(tester, 'a');
    final b = _cameraRect(tester, 'b');
    expect(host.height, greaterThan(550));
    expect(host.left, greaterThan(a.right));
    expect((a.left - b.left).abs(), lessThan(2));
    expect(b.top, greaterThan(a.bottom));
  });

  testWidgets('host plus three guests remain a balanced two-by-two mosaic',
      (tester) async {
    await _render(tester, ['host', 'a', 'b', 'c']);
    final host = _cameraRect(tester, 'host');
    final a = _cameraRect(tester, 'a');
    final b = _cameraRect(tester, 'b');
    final c = _cameraRect(tester, 'c');
    expect((host.top - a.top).abs(), lessThan(2));
    expect((b.top - c.top).abs(), lessThan(2));
    expect(a.left, greaterThan(host.right));
    expect(c.left, greaterThan(b.right));
    expect(b.top, greaterThan(host.bottom));
    expect((host.width - a.width).abs(), lessThan(2));
    expect((host.height - b.height).abs(), lessThan(2));
  });

  testWidgets('board with one participant keeps a full-width camera',
      (tester) async {
    await _render(tester, ['host'], compact: true);
    final host = _cameraRect(tester, 'host');
    expect(host.width, 340);
    expect(host.height, 110);
  });

  testWidgets('board with two participants keeps both cameras wide',
      (tester) async {
    await _render(tester, ['host', 'a'], compact: true);
    final host = _cameraRect(tester, 'host');
    final guest = _cameraRect(tester, 'a');
    expect(host.width, greaterThan(150));
    expect(guest.width, greaterThan(150));
    expect((host.top - guest.top).abs(), lessThan(2));
  });

  testWidgets('board with three participants keeps host large and guests stacked',
      (tester) async {
    await _render(tester, ['host', 'a', 'b'], compact: true);
    final host = _cameraRect(tester, 'host');
    final guestA = _cameraRect(tester, 'a');
    final guestB = _cameraRect(tester, 'b');
    expect(host.height, 110);
    expect((guestA.left - guestB.left).abs(), lessThan(2));
    expect(guestB.top, greaterThan(guestA.bottom));
    expect(guestA.left, greaterThan(host.right));
  });

  testWidgets('board with four participants uses two-by-two wide cameras',
      (tester) async {
    await _render(tester, ['host', 'a', 'b', 'c'], compact: true);
    final host = _cameraRect(tester, 'host');
    final a = _cameraRect(tester, 'a');
    final b = _cameraRect(tester, 'b');
    final c = _cameraRect(tester, 'c');
    expect((host.top - a.top).abs(), lessThan(2));
    expect((b.top - c.top).abs(), lessThan(2));
    expect(a.left, greaterThan(host.right));
    expect(c.left, greaterThan(b.right));
    expect(b.top, greaterThan(host.bottom));
    expect(host.width, greaterThan(150));
  });
}
