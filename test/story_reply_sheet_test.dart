import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/stories/presentation/story_reply_sheet.dart';
import 'package:worldvoice/features/stories/presentation/story_interaction_sheet.dart';
import 'package:worldvoice/features/stories/services/story_service.dart';

class _StoryService extends StoryService {
  int comments = 0;
  @override
  Future<Map<String, dynamic>> fetchStoryInteractions(
    String id, {
    String? viewCursor,
  }) async => {
    'viewers': [],
    'comments': [],
    'likes': [],
    'allowReplies': true,
  };
  @override
  Future<void> commentOnStory(String id, String text) async {
    comments++;
  }
}

void main() {
  testWidgets(
    'private story reply preserves failed draft and queues exactly once on retry',
    (tester) async {
      var attempts = 0;
      final sent = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryReplySheet(
              ownerName: 'Ahmed',
              isArabic: false,
              onSend: (text) async {
                attempts++;
                if (attempts == 1) {
                  throw StateError('Chat request needs approval');
                }
                sent.add(text);
              },
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Beautiful story');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(find.text('Chat request needs approval'), findsOneWidget);
      expect(find.text('Beautiful story'), findsOneWidget);
      expect(sent, isEmpty);
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(sent, ['Beautiful story']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('asynchronous Story comment refresh never returns a Future from setState', (
    tester,
  ) async {
    final service = _StoryService();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryInteractionSheet(
            story: const StoryItem(
              id: 'story2',
              ownerId: 'owner',
              ownerName: 'Ahmed',
              ownerPhotoUrl: '',
              kind: 'image',
              audience: 'everyone',
              durationMs: 7000,
              createdAtMs: 0,
              expiresAtMs: 9999999999999,
              mediaUrl: '',
            ),
            service: service,
            owner: false,
            isArabic: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'رد خاص');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();
    expect(service.comments, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('story activity refresh does not return a Future from setState', (
    tester,
  ) async {
    final service = _StoryService();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryInteractionSheet(
            story: const StoryItem(
              id: 'story1',
              ownerId: 'owner',
              ownerName: 'Ahmed',
              ownerPhotoUrl: '',
              kind: 'image',
              audience: 'everyone',
              durationMs: 7000,
              createdAtMs: 0,
              expiresAtMs: 9999999999999,
              mediaUrl: '',
            ),
            service: service,
            owner: true,
            isArabic: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(service.comments, 0);
  });
}
