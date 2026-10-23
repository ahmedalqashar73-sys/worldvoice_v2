import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/live/services/live_host_channel.dart';

void main() {
  test('Live host channel SHA256 prefix matches Worker implementation', () {
    expect(liveHostChannelPrefix('firebase_uid_123'),
        'live_c7c014818089c02032162815_');
    expect(
      () => liveHostChannelPrefix(''),
      throwsArgumentError,
    );
  });

  test('Live channel has fresh nonce and is safe for Agora/Firestore IDs', () {
    final channel = newLiveHostChannel('firebase_uid_123');
    expect(channel, startsWith(liveHostChannelPrefix('firebase_uid_123')));
    expect(channel, matches(RegExp(r'^live_[a-f0-9]{24}_[a-f0-9]{16,24}$')));
    expect(channel.length, lessThan(64));
    expect(newLiveHostChannel('other_uid'), isNot(channel));
  });
}
