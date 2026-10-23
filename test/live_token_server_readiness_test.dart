import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:worldvoice/features/live/services/live_token_server_readiness.dart';

void main() {
  test('Reports a healthy Worker without inventing an independent Render issuer',
      () async {
    final client = MockClient((request) async {
      if (request.url.host.contains('workers.dev')) {
        return http.Response('{"ok":true}', 200);
      }
      return http.Response(
          '{"ok":true,"agoraTokenConfigured":false}', 200);
    });
    final result = await LiveTokenServerReadiness.check(client: client);
    expect(result.workerReady, isTrue);
    expect(result.renderIndependentIssuer, isFalse);
    expect(result.message(ar: true), contains('إصدار التوكن'));
    client.close();
  });

  test('Explains absent worker readiness and missing independent issuer',
      () async {
    final client = MockClient((request) async {
      if (request.url.host.contains('workers.dev')) {
        return http.Response('{"ok":false}', 503);
      }
      return http.Response(
          '{"ok":true,"agoraTokenConfigured":false}', 200);
    });
    final result = await LiveTokenServerReadiness.check(client: client);
    expect(result.workerReachable, isTrue);
    expect(result.workerReady, isFalse);
    expect(result.renderIndependentIssuer, isFalse);
    expect(result.message(ar: true), contains('شهادة Agora'));
    client.close();
  });

  test('Distinguishes network outage from server configuration', () async {
    final client = MockClient((_) async =>
        throw http.ClientException('Network unreachable'));
    final result = await LiveTokenServerReadiness.check(client: client);
    expect(result.workerReachable, isFalse);
    expect(result.renderReachable, isFalse);
    expect(result.message(ar: true), contains('DNS'));
    client.close();
  });
}
