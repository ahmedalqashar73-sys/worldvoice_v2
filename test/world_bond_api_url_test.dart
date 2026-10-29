import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice_v2/features/profile/presentation/world_bond_screen.dart';

void main() {
  test('WorldBond GET keeps friend ID outside of route path', () {
    final uri = WorldBondApi.endpointUri(
      Uri.parse('https://worldvoice-v2.onrender.com'),
      'world-bond/overview?peerId=friend_123',
    );
    expect(uri.path, '/world-bond/overview');
    expect(uri.queryParameters['peerId'], 'friend_123');
    expect(uri.host, 'worldvoice-v2.onrender.com');
  });

  test('WorldBond daily quiz preserves separate type and peer query keys', () {
    final uri = WorldBondApi.endpointUri(
      Uri.parse('https://worldvoice-v2.onrender.com/api/'),
      'world-bond/challenge?peerId=friend_123&type=language',
    );
    expect(uri.path, '/api/world-bond/challenge');
    expect(uri.queryParameters['peerId'], 'friend_123');
    expect(uri.queryParameters['type'], 'language');
  });

  test('WorldBond refuses external or ambiguous endpoint paths', () {
    final base = Uri.parse('https://worldvoice-v2.onrender.com');
    expect(() => WorldBondApi.endpointUri(base, 'https://other.example/x'),
        throwsStateError);
    expect(() => WorldBondApi.endpointUri(base, '/absolute'),
        throwsStateError);
    expect(() => WorldBondApi.endpointUri(base, 'world-bond/overview#fragment'),
        throwsStateError);
  });
}
