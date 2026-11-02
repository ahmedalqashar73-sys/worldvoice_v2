import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice_v2/features/live/presentation/live_screen.dart';

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

  testWidgets('approved host + 1 guest shows two full-width stacked cameras',
      (tester) async {
    await _render(tester, ['host', 'guest']);
    final host = _cameraRect(tester, 'host');
    final guest = _cameraRect(tester, 'guest');
    expect(guest.top, greaterThan(host.bottom));
    expect((host.left - guest.left).abs(), lessThan(2));
    expect((host.width - guest.width).abs(), lessThan(2));
    expect((host.height - guest.height).abs(), lessThan(2));
    expect(host.width, greaterThan(300));
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

  testWidgets('opening board preserves all four camera thumbnails',
      (tester) async {
    await _render(tester, ['host', 'a', 'b', 'c'], compact: true);
    final top = _cameraRect(tester, 'host');
    final bottom = _cameraRect(tester, 'c');
    expect((top.width - top.height).abs(), lessThan(2));
    expect((top.top - bottom.top).abs(), lessThan(2));
    expect(bottom.right, lessThanOrEqualTo(800));
  });
}
