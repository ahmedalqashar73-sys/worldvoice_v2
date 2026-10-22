import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/live/presentation/live_invitation_card.dart';

void main() {
  test('Live links shared to WhatsApp have a public HTTPS landing URL', () {
    const id = 'live_AbC-123';
    expect(WorldVoiceLiveLinks.web(id),
        'https://worldvoice-v2.onrender.com/live/live_AbC-123');
    expect(WorldVoiceLiveLinks.extract(
      'Join my Live https://worldvoice-v2.onrender.com/live/live_AbC-123'
    ), id);
  });

  test('Legacy in-app Live link remains readable in direct messages', () {
    expect(WorldVoiceLiveLinks.extract(
      'WorldVoice Live\\nworldvoice://live/aB_1234'
    ), 'aB_1234');
  });

  test('Ordinary comments and non-WorldVoice domains are not invitations', () {
    expect(WorldVoiceLiveLinks.extract('This is a Live comment'), isNull);
    expect(WorldVoiceLiveLinks.extract(
      'https://example.com/live/aB_1234'
    ), isNull);
  });
}
