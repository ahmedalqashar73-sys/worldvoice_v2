import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/chat/presentation/worldvoice_shared_content_card.dart';

void main() {
  test('Recognizes WorldVoice Live, room, and story shares', () {
    final live = WorldVoiceSharedLink.parse(
      '🔴 WorldVoice Live\nHi\nAhmed\nworldvoice://live/live_1792800115065');
    expect(live?.kind, SharedContentKind.live);
    expect(live?.id, 'live_1792800115065');

    final room = WorldVoiceSharedLink.parse(
      '🎙 WorldVoice Room\nEnglish\nworldvoice://room/wv_host_123456');
    expect(room?.kind, SharedContentKind.room);
    expect(room?.id, 'wv_host_123456');

    final story = WorldVoiceSharedLink.parse(
      '🌸 WorldVoice Story\nMimi\nworldvoice://story/story_12345');
    expect(story?.kind, SharedContentKind.story);
    expect(story?.id, 'story_12345');
  });

  test('Rejects malformed or unrelated share links', () {
    expect(WorldVoiceSharedLink.parse('hello there'), isNull);
    expect(WorldVoiceSharedLink.parse('worldvoice://room/'), isNull);
    expect(WorldVoiceSharedLink.parse('worldvoice://unknown/my_id123'), isNull);
  });
}
