import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../chat/presentation/worldvoice_chat_gift_card.dart';
import '../../rooms/data/room_backend_config.dart';

/// Public received gifts and owner-only sent history, served by authenticated
/// backend. The client must never read another user's sent ledger directly.
class GiftWallScreen extends StatefulWidget {
  const GiftWallScreen({
    required this.profileUid,
    required this.profileName,
    super.key,
  });

  final String profileUid;
  final String profileName;

  @override
  State<GiftWallScreen> createState() => _GiftWallScreenState();
}

class _GiftWallScreenState extends State<GiftWallScreen> {
  bool _showSent = false;
  late Future<List<Map<String, dynamic>>> _items = _load();

  bool get _mine => FirebaseAuth.instance.currentUser?.uid == widget.profileUid;

  Future<List<Map<String, dynamic>>> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in required');
    if (_showSent && !_mine) throw StateError('Sent gifts are private');
    final root = RoomBackendConfig.giftStoreBaseUrl.trim();
    final endpoint = Uri.tryParse(root);
    if (endpoint == null || endpoint.scheme != 'https' ||
        !endpoint.hasAuthority || endpoint.userInfo.isNotEmpty) {
      throw StateError('Gift wall backend unavailable');
    }
    final url = endpoint.replace(
      path: '${endpoint.path.replaceFirst(RegExp(r"/$"), "")}/gift-wall/${Uri.encodeComponent(widget.profileUid)}',
      queryParameters: {'direction': _showSent ? 'sent' : 'received'},
    );
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw StateError('Please sign in again');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw StateError(response.statusCode == 403
          ? 'This gift wall section is private'
          : 'Could not load gifts (HTTP ${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['ok'] != true || decoded['items'] is! List) {
      throw StateError('Invalid gift wall response');
    }
    return (decoded['items'] as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  void _switchTab(bool sent) {
    if (sent && !_mine) return;
    setState(() {
      _showSent = sent;
      _items = _load();
    });
  }

  void _refresh() => setState(() => _items = _load());

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'حائط الهدايا' : 'Gift Wall'),
        actions: [
          IconButton(
            tooltip: ar ? 'تحديث' : 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.card_giftcard_rounded),
                  label: Text(ar ? 'المستلمة' : 'Received'),
                ),
                if (_mine)
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.lock_outline_rounded),
                    label: Text(ar ? 'المرسلة (خاصة)' : 'Sent (private)'),
                  ),
              ],
              selected: {_showSent},
              onSelectionChanged: (values) => _switchTab(values.first),
            ),
          ),
          Text(
            _showSent
                ? (ar ? 'الهدايا المرسلة تظهر لك وحدك' : 'Only you can see sent gifts')
                : (ar ? 'هدايا ${widget.profileName} المستلمة ظاهرة للجميع'
                      : '${widget.profileName}\'s received gifts are public'),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _items,
              builder: (context, snapshot) {
                if (!snapshot.hasData && !snapshot.hasError) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(ar ? 'تعذر تحميل حائط الهدايا' : 'Could not load gift wall'),
                        const SizedBox(height: 8),
                        Text(snapshot.error.toString(),
                          textAlign: TextAlign.center),
                        TextButton(
                          onPressed: _refresh,
                          child: Text(ar ? 'إعادة المحاولة' : 'Retry'),
                        ),
                      ]),
                    ),
                  );
                }
                final items = snapshot.data ?? const <Map<String, dynamic>>[];
                if (items.isEmpty) {
                  return Center(child: Text(
                    ar ? 'لا توجد هدايا في هذا القسم بعد'
                       : 'No gifts in this section yet',
                  ));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: WorldVoiceChatGiftCard(
                          key: ValueKey(item['id']?.toString() ?? index.toString()),
                          data: item,
                          ar: ar,
                          peerName: _showSent ? (item['recipientName']?.toString() ?? '')
                              : widget.profileName,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
