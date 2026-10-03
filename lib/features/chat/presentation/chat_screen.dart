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
import '../../rooms/services/room_feature_service.dart';
import '../../profile/presentation/public_profile_screen.dart';

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

  /// Reuses the existing authenticated chat backend for cross-feature shares
  /// such as Live links. This keeps membership and mutual-follow checks in the
  /// backend instead of writing chat messages directly from Firestore clients.
  static Future<void> sendTextMessageToConversation({
    required String chatId,
    required String text,
  }) async {
    final value = text.trim();
    if (value.isEmpty) return;
    final random = Random.secure();
    final requestKey = List<int>.generate(24, (_) => random.nextInt(256))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    await _post(
      '/chat/message',
      <String, dynamic>{'chatId': chatId, 'text': value},
      requestKey: requestKey,
    );
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
                            final profileData =
                                profile.data?.data() ?? const <String, dynamic>{};
                            final displayName = (profileData['displayName'] ??
                                profileData['name'] ?? peerId).toString();
                            final photo =
                                (profileData['photoUrl'] ?? '').toString().trim();
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    photo.isEmpty ? null : NetworkImage(photo),
                                child: photo.isEmpty
                                    ? const Icon(Icons.person_outline)
                                    : null,
                              ),
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
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: ar ? 'تجربة الهدايا الثلاثين'
                    : 'Preview 30 gifts',
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  showDragHandle: true,
                  builder: (sheet) => SizedBox(
                    height: MediaQuery.sizeOf(sheet).height * .76,
                    child: const UnifiedGiftPanel(
                      contextType: 'chat',
                      contextId: 'preview',
                      recipients: <String, String>{},
                    ),
                  ),
                ),
                icon: const Icon(Icons.card_giftcard_outlined,
                    color: Color(0xFF11835D)),
              ),
              IconButton.filledTonal(
                tooltip: ar ? 'محادثة جديدة' : 'New chat',
                onPressed: ready ? () => _startChat(context, ar, uid) : null,
                icon: const Icon(Icons.edit_rounded),
              ),
            ]),
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
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: chats.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 78),
                  itemBuilder: (context, index) {
                    final snap = chats[index];
                    final data = snap.data();
                    final ids = List<String>.from(data['memberIds'] ?? []);
                    final peer = ids.firstWhere(
                      (value) => value != uid,
                      orElse: () => '',
                    );
                    if (peer.isEmpty) return const SizedBox.shrink();
                    final names = Map<String, dynamic>.from(
                      data['memberNames'] as Map? ?? <String, dynamic>{},
                    );
                    final name = (names[peer] ?? peer).toString();
                    return _ConversationTile(
                      peerId: peer,
                      peerName: name,
                      latestText: (data['latestText'] ?? '').toString(),
                      onOpenConversation: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _ChatConversation(
                            chatId: snap.id,
                            peerId: peer,
                            peerName: name,
                          ),
                        ),
                      ),
                      onOpenProfile: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PublicProfileScreen(
                            userId: peer,
                            localeController: localeController,
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

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.peerId,
    required this.peerName,
    required this.latestText,
    required this.onOpenConversation,
    required this.onOpenProfile,
  });

  final String peerId;
  final String peerName;
  final String latestText;
  final VoidCallback onOpenConversation;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(peerId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final photo = (data['photoUrl'] ?? '').toString().trim();
        final name = (data['displayName'] ?? data['name'] ?? peerName)
            .toString()
            .trim();
        final online = data['isOnline'] == true;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 5,
          ),
          leading: InkWell(
            customBorder: const CircleBorder(),
            onTap: onOpenProfile,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundImage:
                      photo.isEmpty ? null : NetworkImage(photo),
                  child:
                      photo.isEmpty ? const Icon(Icons.person_rounded) : null,
                ),
                if (online)
                  PositionedDirectional(
                    end: -1,
                    bottom: 1,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          title: Text(
            name.isEmpty ? peerName : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            latestText.isEmpty ? ' ' : latestText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: onOpenConversation,
        );
      },
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
  StreamSubscription<List<RoomGiftPreview>>? _friendGiftPreviewSub;
  final Set<String> _seenFriendPreviewEvents = <String>{};

  @override
  void initState() {
    super.initState();
    if (RoomFeatureService.friendPreviewEnabled) {
      _friendGiftPreviewSub = RoomFeatureService.watchFriendGiftPreviews(
        context: 'chat', contextId: widget.chatId,
      ).listen((previews) {
        final now = DateTime.now();
        RoomGiftPreview? latest;
        for (final event in previews) {
          final sent = event.sentAt;
          // The initial local Firestore write can contain a pending
          // serverTimestamp; don't mark it seen before the real ack.
          if (sent == null) continue;
          final newEvent = _seenFriendPreviewEvents.add(event.eventKey);
          if (!newEvent ||
              sent.isBefore(_conversationOpenedAt.subtract(
                  const Duration(seconds: 1))) ||
              now.difference(sent).inSeconds.abs() > 20) {
            continue;
          }
          latest ??= event;
        }
        if (latest != null) {
          final demo = latest;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showGiftAnimation(demo.toVisualEvent(), preview: true);
            }
          });
        }
      }, onError: (Object error, StackTrace trace) {
        debugPrint('WorldVoice chat gift demos unavailable: $error');
      });
    }
  }

  void _showIncomingGift(
      QueryDocumentSnapshot<Map<String, dynamic>> message) {
    if (!mounted) return;
    final data = message.data();
    _showGiftAnimation(RoomGiftEvent(
      id: message.id,
      senderId: (data['senderId'] ?? '').toString(),
      senderName: (data['senderName'] ?? '').toString(),
      recipientId: (data['recipientId'] ?? '').toString(),
      recipientName: (data['recipientName'] ?? '').toString(),
      giftId: (data['giftId'] ?? '').toString(),
      points: (data['points'] as num?)?.toInt() ?? 0,
      animationUrl: data['animationUrl']?.toString(),
    ));
  }

  void _showGiftAnimation(RoomGiftEvent event, {bool preview = false}) {
    if (!mounted) return;
    _giftTimer?.cancel();
    _giftOverlay?.remove();
    final overlay = OverlayEntry(
      builder: (_) => RoomGiftOverlay(event: event, preview: preview),
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
    _friendGiftPreviewSub?.cancel();
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
      appBar: AppBar(
        titleSpacing: 0,
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.peerId)
              .snapshots(),
          builder: (context, snapshot) {
            final data =
                snapshot.data?.data() ?? const <String, dynamic>{};
            final photo = (data['photoUrl'] ?? '').toString().trim();
            final name = (data['displayName'] ??
                    data['name'] ??
                    widget.peerName)
                .toString();
            final online = data['isOnline'] == true;
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PublicProfileScreen(
                    userId: widget.peerId,
                    languageCode:
                        Localizations.localeOf(context).languageCode,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(2, 4, 8, 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage:
                          photo.isEmpty ? null : NetworkImage(photo),
                      child: photo.isEmpty
                          ? const Icon(Icons.person_rounded, size: 18)
                          : null,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            online
                                ? (ar ? 'متصل الآن' : 'Online')
                                : (ar ? 'غير متصل' : 'Offline'),
                            style: TextStyle(
                              fontSize: 11,
                              color: online
                                  ? Colors.green
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
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
                            color: classicGift ? null
                                : mine
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                            gradient: classicGift ? const LinearGradient(
                              colors: [Color(0xFF124C37), Color(0xFF1B5942),
                                       Color(0xFF0A382B)]) : null,
                            border: classicGift
                                ? Border.all(color: const Color(0xBBE6C881))
                                : null,
                            boxShadow: classicGift ? const [
                              BoxShadow(color: Color(0x332AAC74),
                                  blurRadius: 12, offset: Offset(0, 4)),
                            ] : null,
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
                                    final sender = (data['senderName'] ??
                                        (ar ? 'المرسل' : 'Sender')).toString();
                                    final receiver = (data['recipientName'] ??
                                        widget.peerName).toString();
                                    final paidCoins =
                                        (data['points'] as num?)?.toInt();
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.auto_awesome_rounded,
                                          color: Color(0xFFF5D893), size: 15),
                                        const SizedBox(height: 2),
                                        Text(ar
                                          ? '$sender أهدى إلى $receiver'
                                          : '$sender sent to $receiver',
                                          maxLines: 2,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFFFFE7AC),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12)),
                                        ClassicGiftVisual(
                                            gift: gift, size: 115),
                                        Text(gift.localizedName(ar),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900)),
                                        const SizedBox(height: 3),
                                        Text('${paidCoins ?? gift.priceCoins} 🪙',
                                            style: const TextStyle(
                                              color: Color(0xFFFFD98E),
                                              fontWeight: FontWeight.w900)),
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