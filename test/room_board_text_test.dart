import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/presentation/room_board_content.dart';

void main() {
  testWidgets('Done saves text and safely removes focused editor', (tester) async {
    String? saved;
    bool editing = true;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatefulBuilder(
      builder: (context, update) => editing ? BoardTextInput(
        onSave: (value) async { saved = value; },
        onClose: () => update(() => editing = false)) : const Text('Board')))));
    await tester.enterText(find.byType(TextField), 'Hello room');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(saved, 'Hello room');
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('failed save keeps text available for retry', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: BoardTextInput(
      onSave: (_) async => throw StateError('offline'), onClose: () {}))));
    await tester.enterText(find.byType(TextField), 'Keep this');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Keep this'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
