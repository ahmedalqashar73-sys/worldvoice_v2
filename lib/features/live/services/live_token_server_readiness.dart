import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../rooms/data/agora_config.dart';
import '../../rooms/data/room_backend_config.dart';

/// Public, read-only diagnostics. Never sends Firebase tokens or secrets.
class LiveTokenServerReadiness {
  const LiveTokenServerReadiness({
    required this.workerReachable,
    required this.workerReady,
    required this.renderReachable,
    required this.renderIndependentIssuer,
  });

  final bool workerReachable;
  final bool workerReady;
  final bool renderReachable;
  final bool renderIndependentIssuer;

  String message({required bool ar}) {
    if (!workerReady && !renderIndependentIssuer) {
      return ar
          ? 'خدمة توكن Agora غير جاهزة: Cloudflare Worker لا يعلن الجاهزية '
            'وخادم Render لا يملك مُصدِر توكن مستقلًا. افحص نشر Worker '
            'وشهادة Agora على الخادم، ثم أعد المحاولة.'
          : 'Agora token service is not ready: Cloudflare Worker is not '
            'reporting ready and Render has no independent token issuer. '
            'Check the Worker deployment and the server Agora certificate.';
    }
    if (workerReady || renderIndependentIssuer) {
      return ar
          ? 'أحد خوادم Agora يبدو جاهزًا عبر فحص الصحة، لكن إصدار التوكن '
            'فشل. راجع سجلات طلب POST /agora/token وصلاحيات Firebase '
            'ووقت الاستجابة.'
          : 'An Agora service reports healthy, but token issuance failed. '
            'Inspect POST /agora/token logs, Firebase authorization and latency.';
    }
    return ar
        ? 'تعذر التحقق من خوادم Agora. اختبر اتصال الإنترنت وشبكة DNS '
          'وافتح رابط /health لخدمة Cloudflare وRender من جوالك.'
        : 'Agora health probes failed. Check device network and DNS, '
          'then open the Cloudflare and Render /health pages.';
  }

  static Future<LiveTokenServerReadiness> check({http.Client? client}) async {
    final ownClient = client == null;
    final requestClient = client ?? http.Client();
    Future<Map<String, dynamic>?> probe(String uri) async {
      final parsed = Uri.tryParse(uri);
      if (parsed == null || parsed.scheme != 'https') return null;
      try {
        final response = await requestClient.get(parsed)
            .timeout(const Duration(seconds: 5));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return <String, dynamic>{'_reachable': true};
        }
        final decoded = jsonDecode(response.body);
        return decoded is Map<String, dynamic>
            ? <String, dynamic>{...decoded, '_reachable': true}
            : <String, dynamic>{'_reachable': true};
      } catch (_) {
        return null;
      }
    }

    try {
      final workerUrl = Uri.parse(AgoraConfig.stableTokenEndpoint)
          .replace(path: '/health', query: '').toString();
      final backendUrl = RoomBackendConfig.endpoint('/health');
      final results = await Future.wait([
        probe(workerUrl),
        probe(backendUrl),
      ]);
      final worker = results[0];
      final render = results[1];
      return LiveTokenServerReadiness(
        workerReachable: worker != null,
        workerReady: worker?['ok'] == true,
        renderReachable: render != null,
        renderIndependentIssuer: render?['agoraTokenConfigured'] == true,
      );
    } finally {
      if (ownClient) requestClient.close();
    }
  }
}
