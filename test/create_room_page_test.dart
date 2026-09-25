import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/room_mode.dart';
import 'package:worldvoice/features/rooms/presentation/create_room_page.dart';

void main() {
  testWidgets('Arabic creation scrolls with keyboard on a small display', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      const MaterialApp(
        home: CreateRoomPage(
          isArabic: true,
          languageOptions: ['ar', 'en'],
          initialLanguage: 'ar',
          giftLevel: 0,
        ),
      ),
    );
    await tester.tap(find.byType(TextFormField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextFormField), 'غرفة التعلم');
    await tester.dragUntilVisible(find.text('بدء الغرفة الصوتية').hitTestable(), find.byType(SingleChildScrollView).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(find.text('بدء الغرفة الصوتية').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected mode and trimmed title return to the room flow', (
    tester,
  ) async {
    CreateRoomResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              child: const Text('Open'),
              onPressed: () async {
                result = await Navigator.of(context).push<CreateRoomResult>(
                  MaterialPageRoute(
                    builder: (_) => const CreateRoomPage(
                      isArabic: false,
                      languageOptions: ['en'],
                      initialLanguage: 'en',
                      giftLevel: 14,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '  Practice together  ');
    await tester.scrollUntilVisible(find.text('Quiz'), 120, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quiz'));
    await tester.scrollUntilVisible(find.text('Start voice room'), 180, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start voice room'));
    await tester.pumpAndSettle();
    expect(result?.name, 'Practice together');
    expect(result?.mode, RoomMode.quiz);
    expect(result?.languageCode, 'en');
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text remains scrollable and an empty name is rejected', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: const CreateRoomPage(
          isArabic: false,
          languageOptions: ['en'],
          initialLanguage: 'en',
          giftLevel: 0,
        ),
      ),
    );
    await tester.scrollUntilVisible(find.text('Start voice room'), 180, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start voice room'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateRoomPage), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Enter a room name'), -180, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('Enter a room name'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
