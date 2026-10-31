import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/room_backend_config.dart';

void main() {
  test('private and group call tokens use the social server, not room backend', () {
    final social = RoomBackendConfig.socialEndpoint('/agora/token');
    expect(social, isNotEmpty);
    expect(
      RoomBackendConfig.agoraTokenEndpointForChannel('call_abc123'),
      social,
    );
    expect(
      RoomBackendConfig.agoraTokenEndpointForChannel('group_abc123'),
      social,
    );
    expect(Uri.parse(social).host,
      Uri.parse(RoomBackendConfig.socialBaseUrl).host);
  });

  test('Live and voice rooms keep their established token routing', () {
    expect(
      RoomBackendConfig.agoraTokenEndpointForChannel('live_123456'),
      RoomBackendConfig.aiEndpoint('/agora/token'),
    );
    expect(
      RoomBackendConfig.agoraTokenEndpointForChannel('regular_room'),
      RoomBackendConfig.endpoint('/agora/token'),
    );
  });
}
