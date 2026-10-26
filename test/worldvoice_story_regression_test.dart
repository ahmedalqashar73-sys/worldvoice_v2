import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/stories/services/story_service.dart';

void main() {
  test('Stories response preserves published media, author and expiry', () {
    final story = StoryItem.fromJson({
      'id': 'published-story-123',
      'ownerId': 'alice',
      'ownerName': 'Alice',
      'ownerPhotoUrl': 'https://example.org/avatar.png',
      'kind': 'image',
      'audience': 'everyone',
      'durationMs': 7000,
      'createdAtMs': 1760000000000,
      'expiresAtMs': 1760086400000,
      'mediaUrl': 'https://example.org/stories/1.jpg',
    });
    expect(story.id, 'published-story-123');
    expect(story.ownerId, 'alice');
    expect(story.isVideo, isFalse);
    expect(story.isCloseFriends, isFalse);
    expect(story.mediaUrl, contains('/stories/1.jpg'));
    expect(story.expiresAtMs - story.createdAtMs, 86400000);
  });

  test('Close Friends video metadata supports 90 second Stories', () {
    final story = StoryItem.fromJson({
      'id': 'video-story-456',
      'ownerId': 'bob',
      'ownerName': 'Bob',
      'kind': 'video',
      'audience': 'close_friends',
      'durationMs': 90000,
      'mediaUrl': 'https://example.org/signed/video.mp4',
    });
    expect(story.isVideo, isTrue);
    expect(story.isCloseFriends, isTrue);
    expect(story.durationMs, 90000);
  });

  test('Story metadata handles missing optional fields', () {
    final story = StoryItem.fromJson({
      'id': 'story-3', 'ownerId': 'member', 'mediaUrl': 'https://example.org/m.jpg',
    });
    expect(story.kind, 'image');
    expect(story.audience, 'everyone');
    expect(story.durationMs, 7000);
    expect(story.ownerName, 'WorldVoice');
  });
}
