import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/localization/locale_controller.dart';
import '../../rooms/presentation/unified_gift_panel.dart';
import '../../rooms/presentation/classic_gift_visual.dart';
import '../../rooms/presentation/room_gift_overlay.dart';
import '../../rooms/data/classic_gift_catalog.dart';
import '../../rooms/data/room_feature_models.dart';

/// Real authenticated conversations. The economy backend, not Flutter,
/// establishes mutual-follower membership and writes chat/gift messages.
class ChatScreen extends StatelessWidget {
  const ChatScreen({required this.localeController, super.key});
  final LocaleController localeController;

  static const _backend = String.fromEnvironment('WORLDVOICE_ECONOMY_ENDPOINT');

  static Future<Map<String, dynamic>> _post(
    String route, Map<String, dynamic> payload, {String? requestKey,}
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to chat.');
    final uri = Uri.tryParse(_backend.trim());
    if (uri == null || uri.scheme != 'https' || !uri.hasAuthority ||
        uri.userInfo.isNotEmpty || uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      throw StateError('Chat backend is not deployed yet.');
    }
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw StateError('Could not authenticate your chat session.');
    }
    final path = uri.path.endsWith('/')
        ? uri.path.substring(0, uri.path.length - 1) : uri.path;
    final result = await http.post(
      uri.replace(path: '$path$route'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        ...(requestKey == null ? <String, String>{} :
          <String, String>{'Idempotency-Key': requestKey}),
      },
      body: jsonEncode(payload),
    );
    Map<String, dynamic> body;
    try {
      final raw = jsonDecode(result.body);
      body = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    } catch (_) {
      throw StateError('The chat server sent an invalid response.');
    }
    if (result.statusCode < 200 || result.statusCode >= 300 ||
        body['ok'] != true) {
      throw StateError(body['error']?.toString() ?? 'Chat request failed.');
    }
    return body;
  }

  Future<void> _startChat(BuildContext parentContext, bool ar, String uid) async {
    final db = FirebaseFirestore.instance;
    await showModalBottomSheet<void>(
      context: parentContext,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .65,
          child: Column(
            children: [
              ListTile(
                title: Text(ar ? 'اختر صديقًا' : 'Choose a friend',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(ar
                    ? 'المحادثة متاحة للأصدقاء الذين يتابعون بعضهم.'
                    : 'Chat requires both people to follow each other.'),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: db.collection('users').doc(uid)
                      .collection('following').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text(ar
                          ? 'تعذر تحميل الأصدقاء' : 'Could not load friends'));
                    }
                    final peers = snapshot.data?.docs ??
                        <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                    if (peers.isEmpty) {
                      return Center(child: Text(ar
                          ? 'ليس لديك أصدقاء بعد' : 'No contacts yet'));
                    }
                    return ListView.builder(
                      itemCount: peers.length,
                      itemBuilder: (context, index) {
                        final peerId = peers[index].id;
                        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          future: db.collection('users').doc(peerId).get(),
                          builder: (context, profile) {
                            final displayName = (profile.data?.data()?['displayName'] ??
                                profile.data?.data()?['name'] ?? peerId).toString();
                            return ListTile(
                              leading: const CircleAvatar(
                                  child: Icon(Icons.person_outline)),
                              title: Text(displayName),
                              onTap: () async {
                                try {
                                  final result = await _post('/chat/start',
                                      {'recipientId': peerId});
                                  if (!sheetContext.mounted) return;
                                  Navigator.pop(sheetContext);
                                  if (!parentContext.mounted) return;
                                  await Navigator.of(parentContext).push(MaterialPageRoute<void>(
                                    builder: (_) => _ChatConversation(
                                      chatId: result['chatId'].toString(),
                                      peerId: peerId, peerName: displayName,
                                    ),
                                  ));
                                } catch (error) {
                                  if (!sheetContext.mounted) return;
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    SnackBar(content: Text(
                                        error.toString().replaceFirst('Bad state: ', ''))),
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final ar = (localeController.locale?.languageCode ??
        Localizations.localeOf(context).languageCode) == 'ar';
    if (uid == null) {
      return Center(child: Text(ar ? 'سجّل دخولك أولًا' : 'Sign in to use chat.'));
    }
    final ready = Uri.tryParse(_backend)?.scheme == 'https';
    return SafeArea(
      child: Column(
        children: [
          ListTile(
            title: Text(ar ? 'الدردشة' : 'Messages',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900)),
            subtitle: !ready
                ? Text(ar
                    ? 'بانتظار نشر سيرفر المحادثة الآمن'
                    : 'Secure chat backend is not deployed yet')
                : null,
            trailing: IconButton.filledTonal(
              tooltip: ar ? 'محادثة جديدة' : 'New chat',
              onPressed: ready ? () => _startChat(context, ar, uid) : null,
              icon: const Icon(Icons.edit_rounded),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('chats')
                  .where('memberIds', arrayContains: uid)
                  .where('active', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(ar
                      ? 'تعذر تحميل المحادثات. تحقق من قواعد Firebase.'
                      : 'Chat unavailable; check Firestore rules and indexes.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final chats = snapshot.data!.docs.toList()
                  ..sort((a, b) {
                    final one = a.data()['lastMessageAt'];
                    final two = b.data()['lastMessageAt'];
                    final first = one is Timestamp ? one.millisecondsSinceEpoch : 0;
                    final second = two is Timestamp ? two.millisecondsSinceEpoch : 0;
                    return second.compareTo(first);
                  });
                if (chats.isEmpty) {
                  return Center(child: Text(ar
                      ? 'لا توجد محادثات حقيقية بعد'
                      : 'No conversations yet'));
                }
                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final snap = chats[index];
                    final data = snap.data();
                    final ids = List<String>.from(data['memberIds'] ?? []);
                    final peer = ids.firstWhere((value) => value != uid,
                        orElse: () => '');
                    if (peer.isEmpty) return const SizedBox.shrink();
                    final names = Map<String, dynamic>.from(
                        data['memberNames'] as Map? ?? <String, dynamic>{});
                    final name = (names[peer] ?? peer).toString();
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(name),
                      subtitle: Text((data['latestText'] ?? '').toString(),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _ChatConversation(
                            chatId: snap.id, peerId: peer, peerName: name,
                          ),
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

class _ChatConversation extends StatefulWidget {
  const _ChatConversation({
    required this.chatId, required this.peerId, required this.peerName,
  });
  final String chatId;
  final String peerId;
  final String peerName;

  @override
  State<_ChatConversation> createState() => _ChatConversationState();
}

class _ChatConversationState extends State<_ChatConversation> {
  final _text = TextEditingController();
  final _knownGiftIds = <String>{};
  final DateTime _conversationOpenedAt = DateTime.now();
  bool _giftStreamPrimed = false;
  OverlayEntry? _giftOverlay;
  Timer? _giftTimer;

  void _showIncomingGift(
      QueryDocumentSnapshot<Map<String, dynamic>> message) {
    if (!mounted) return;
    final data = message.data();
    _giftTimer?.cancel();
    _giftOverlay?.remove();
    final event = RoomGiftEvent(
      id: message.id,
      senderId: (data['senderId'] ?? '').toString(),
      senderName: (data['senderName'] ?? '').toString(),
      recipientId: (data['recipientId'] ?? '').toString(),
      recipientName: (data['recipientName'] ?? '').toString(),
      giftId: (data['giftId'] ?? '').toString(),
      points: (data['points'] as num?)?.toInt() ?? 0,
      animationUrl: data['animationUrl']?.toString(),
    );
    final overlay = OverlayEntry(
      builder: (_) => RoomGiftOverlay(event: event),
    );
    _giftOverlay = overlay;
    Overlay.of(context).insert(overlay);
    _giftTimer = Timer(const Duration(seconds: 3), () {
      if (_giftOverlay == overlay) {
        overlay.remove();
        _giftOverlay = null;
      }
    });
  }

  void _observeGiftMessages(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> messages) {
    final gifts = messages.where((doc) => doc.data()['type'] == 'gift').toList();
    if (!_giftStreamPrimed) {
      _giftStreamPrimed = true;
      _knownGiftIds.addAll(gifts.map((doc) => doc.id));
      return;
    }
    final incoming = gifts.where(
      (doc) => _knownGiftIds.add(doc.id)).toList();
    if (incoming.isEmpty) return;
    // Firestore can first show cached empty results then load history.
    // Replayed older gifts belong in the transcript, not a new animation.
    final latest = incoming.first;
    final timestamp = latest.data()['createdAt'];
    if (timestamp is! Timestamp ||
        timestamp.toDate().isBefore(
            _conversationOpenedAt.subtract(const Duration(seconds: 2)))) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showIncomingGift(incoming.first);
    });
  }
  bool _sending = false;
  String? _pendingText;
  String? _pendingKey;

  String _newRequestKey() {
    final random = Random.secure();
    return List<int>.generate(24, (_) => random.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> _send() async {
    final message = _text.text.trim();
    if (message.isEmpty || _sending) return;
    if (_pendingText != message || _pendingKey == null) {
      _pendingText = message;
      _pendingKey = _newRequestKey();
    }
    setState(() => _sending = true);
    try {
      await ChatScreen._post('/chat/message', {
        'chatId': widget.chatId, 'text': message,
      }, requestKey: _pendingKey);
      if (!mounted) return;
      _text.clear();
      _pendingKey = null;
      _pendingText = null;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.toString().replaceFirst('Bad state: ', '')),
      ));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showGifts() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: UnifiedGiftPanel(
          contextType: 'chat', contextId: widget.chatId,
          recipients: {widget.peerId: widget.peerName},
        ),
      ),
    );
  }

  @override
  void dispose() {
    _giftTimer?.cancel();
    _giftOverlay?.remove();
    _giftOverlay = null;
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(widget.peerName)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('chats').doc(widget.chatId)
                    .collection('messages')
                    .orderBy('createdAt', descending: true)
                    .limit(100).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text(ar
                        ? 'تعذر تحميل رسائل هذه المحادثة'
                        : 'Messages unavailable'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data!.docs;
                  _observeGiftMessages(messages);
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final data = messages[index].data();
                      final mine = data['senderId'] == uid;
                      final isGift = data['type'] == 'gift';
                      final giftId = (data['giftId'] ?? '').toString();
                      final classicGift = isGift &&
                          giftId.startsWith('classic_');
                      final value = isGift
                          ? (ar ? '🎁 هدية: $giftId' : '🎁 Gift: $giftId')
                          : (data['text'] ?? '').toString();
                      return Align(
                        alignment: mine ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 300),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: classicGift
                                ? Colors.transparent
                                : mine
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: classicGift
                              ? FutureBuilder<List<RoomGiftCatalogItem>>(
                                  future: ClassicGiftCatalog.load(),
                                  builder: (context, giftSnapshot) {
                                    RoomGiftCatalogItem? gift;
                                    for (final item in giftSnapshot.data ??
                                        const <RoomGiftCatalogItem>[]) {
                                      if (item.id == giftId) {
                                        gift = item;
                                        break;
                                      }
                                    }
                                    if (gift == null) return Text(value);
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ClassicGiftVisual(
                                            gift: gift, size: 100),
                                        Text(gift.localizedName(ar),
                                            style: const TextStyle(
                                              color: Color(0xFF0D7654),
                                              fontWeight: FontWeight.w800)),
                                        Text('${gift.priceCoins} 🪙',
                                            style: const TextStyle(
                                              color: Color(0xFFB58A2A),
                                              fontWeight: FontWeight.bold)),
                                      ],
                                    );
                                  },
                                )
                              : isGift
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                            Icons.card_giftcard, size: 36),
                                        Text(value),
                                      ])
                                  : Text(value),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Row(
              children: [
                PopupMenuButton<String>(
                  tooltip: ar ? 'المزيد' : 'More',
                  icon: const Icon(Icons.add_circle_outline),
                  onSelected: (value) {
                    if (value == 'gift') _showGifts();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'gift',
                      child: Text(ar ? 'إرسال هدية' : 'Send Gift'),
                    ),
                  ],
                ),
                Expanded(
                  child: TextField(
                    controller: _text,
                    minLines: 1, maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    onChanged: (value) {
                      if (_pendingText != value.trim()) {
                        _pendingKey = null;
                      }
                    },
                    decoration: InputDecoration(
                      hintText: ar ? 'اكتب رسالة...' : 'Message...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: ar ? 'إرسال' : 'Send',
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
