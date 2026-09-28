import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import '../../rooms/presentation/unified_gift_panel.dart';

/// No mock chats: only real mutually accepted Firebase conversations can
/// exchange messages or receive paid gift events.
class ChatScreen extends StatefulWidget {
  const ChatScreen({required this.localeController, super.key});
  final LocaleController localeController;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _db = FirebaseFirestore.instance;
  String _search = '';

  Future<void> _invite(BuildContext context, String uid) async {
    final follows = await _db.collection('users').doc(uid)
        .collection('following').get();
    if (!context.mounted) return;
    final friendId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('New conversation'),
        children: [
          if (follows.docs.isEmpty) const Padding(
            padding: EdgeInsets.all(18), child: Text('Follow a person first.')),
          for (final contact in follows.docs)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, contact.id),
              child: Text(contact.data()['displayName']?.toString() ?? contact.id),
            ),
        ],
      ),
    );
    if (friendId == null || !context.mounted) return;
    final existing = await _db.collection('conversations')
      .where('members', arrayContains: uid).get();
    for (final doc in existing.docs) {
      final members = (doc.data()['members'] as List?) ?? const [];
      if (members.length == 2 && members.contains(friendId)) {
        if (!context.mounted) return;
        _openConversation(context, doc.id, friendId);
        return;
      }
    }
    final document = _db.collection('conversations').doc();
    try {
      await document.set({
        'members': [uid, friendId],
        'acceptedBy': [uid],
        'status': 'invited',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation sent. Messaging begins after acceptance.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not invite: $error')),
      );
    }
  }

  void _openConversation(BuildContext context, String conversationId,
      String otherUid) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => _DirectConversationScreen(
        conversationId: conversationId, otherUid: otherUid),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.localeController.locale?.languageCode ?? 'en';
    final rtl = const {'ar', 'ur', 'fa'}.contains(code);
    final ar = code == 'ar';
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text(ar ? 'سجّل الدخول لعرض الدردشة' : 'Sign in to see chats'));
    }
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          Expanded(child: Text(ar ? 'الدردشة' : 'Chat',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900))),
          IconButton.filledTonal(
            onPressed: () => _invite(context, user.uid),
            tooltip: ar ? 'محادثة جديدة' : 'New conversation',
            icon: const Icon(Icons.edit_rounded),
          ),
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(
          onChanged: (value) => setState(() => _search = value.toLowerCase().trim()),
          decoration: InputDecoration(
            hintText: ar ? 'ابحث في المحادثات' : 'Search conversations',
            prefixIcon: const Icon(Icons.search_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          ),
        )),
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db.collection('conversations')
              .where('members', arrayContains: user.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(ar ? 'تعذر عرض المحادثات' : 'Chats unavailable'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return Center(child: Text(ar
                  ? 'لا توجد محادثات بعد. اضغط القلم للدعوة.'
                  : 'No conversations yet. Tap the pencil to invite.'));
            }
            return ListView.builder(itemCount: docs.length,
              itemBuilder: (context, index) {
                final conversation = docs[index];
                final data = conversation.data();
                final members = (data['members'] as List?)
                    ?.map((value) => value.toString()).toList() ?? [];
                final accepted = (data['acceptedBy'] as List?) ?? [];
                final other = members.where((id) => id != user.uid).firstOrNull;
                if (other == null) return const SizedBox.shrink();
                return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: _db.collection('users').doc(other).get(),
                  builder: (context, otherSnapshot) {
                    final name = otherSnapshot.data?.data()?['displayName']?.toString()
                        ?? other;
                    if (_search.isNotEmpty && !name.toLowerCase().contains(_search)) {
                      return const SizedBox.shrink();
                    }
                    final awaitingMe = !accepted.contains(user.uid);
                    final ready = data['status'] == 'active' &&
                        accepted.contains(user.uid) && accepted.contains(other);
                    return ListTile(
                      leading: CircleAvatar(child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?')),
                      title: Text(name),
                      subtitle: Text(ready
                        ? (ar ? 'المحادثة نشطة' : 'Active conversation')
                        : awaitingMe
                            ? (ar ? 'دعوة بانتظار موافقتك' : 'Accept invitation')
                            : (ar ? 'بانتظار قبول الطرف الآخر'
                                : 'Awaiting other member')),
                      trailing: awaitingMe ? FilledButton(
                        onPressed: () async {
                          try {
                            await conversation.reference.update({
                              'acceptedBy': [user.uid, other],
                              'status': 'active',
                              'updatedAt': FieldValue.serverTimestamp(),
                            });
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        },
                        child: Text(ar ? 'قبول' : 'Accept'),
                      ) : const Icon(Icons.chevron_right),
                      onTap: ready
                          ? () => _openConversation(context, conversation.id, other)
                          : null,
                    );
                  },
                );
              },
            );
          },
        )),
      ])),
    );
  }
}

class _DirectConversationScreen extends StatefulWidget {
  const _DirectConversationScreen({
    required this.conversationId, required this.otherUid,
  });
  final String conversationId;
  final String otherUid;
  @override
  State<_DirectConversationScreen> createState() =>
      _DirectConversationScreenState();
}

class _DirectConversationScreenState extends State<_DirectConversationScreen> {
  final _message = TextEditingController();
  final _db = FirebaseFirestore.instance;
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final text = _message.text.trim();
    if (uid == null || text.isEmpty || text.length > 2000 || _sending) return;
    setState(() => _sending = true);
    try {
      await _db.collection('conversations').doc(widget.conversationId)
          .collection('messages').add({
        'senderId': uid,
        'text': text,
        'type': 'text',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _message.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showGifts() {
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true,
      builder: (_) => SafeArea(child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: UnifiedGiftPanel(
          contextType: 'chat',
          contextId: widget.conversationId,
          recipients: {widget.otherUid: widget.otherUid},
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Sign in')));
    final messages = _db.collection('conversations').doc(widget.conversationId)
        .collection('messages').orderBy('createdAt', descending: true)
        .limit(100).snapshots();
    final gifts = _db.collection('conversations').doc(widget.conversationId)
        .collection('gifts').orderBy('createdAt', descending: true)
        .limit(100).snapshots();
    return Scaffold(
      appBar: AppBar(title: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _db.collection('users').doc(widget.otherUid).get(),
        builder: (context, snapshot) =>
            Text(snapshot.data?.data()?['displayName']?.toString() ?? 'Chat'),
      )),
      body: SafeArea(child: Column(children: [
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: messages,
          builder: (context, messageSnap) {
            if (messageSnap.hasError) {
              return const Center(child: Text('Messages unavailable'));
            }
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: gifts,
              builder: (context, giftSnap) {
                final feed = <_ChatFeedEntry>[
                  for (final msg in messageSnap.data?.docs ??
                      <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                    _ChatFeedEntry(
                      id: msg.id,
                      time: (msg.data()['createdAt'] as Timestamp?)?.toDate(),
                      senderId: msg.data()['senderId']?.toString() ?? '',
                      text: msg.data()['text']?.toString() ?? '',
                    ),
                  for (final gift in giftSnap.data?.docs ??
                      <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                    _ChatFeedEntry(
                      id: gift.id,
                      time: (gift.data()['createdAt'] as Timestamp?)?.toDate(),
                      senderId: gift.data()['senderId']?.toString() ?? '',
                      text: gift.data()['senderName']?.toString() ?? 'Gift',
                      animationUrl: gift.data()['animationUrl']?.toString(),
                      giftId: gift.data()['giftId']?.toString(),
                    ),
                ]..sort((a, b) => (b.time ?? DateTime.fromMillisecondsSinceEpoch(0))
                    .compareTo(a.time ?? DateTime.fromMillisecondsSinceEpoch(0)));
                if (feed.isEmpty) {
                  return const Center(child: Text('Write your first message.'));
                }
                return ListView.builder(
                  reverse: true, padding: const EdgeInsets.all(12),
                  itemCount: feed.length,
                  itemBuilder: (context, i) {
                    final item = feed[i];
                    final mine = item.senderId == uid;
                    return Align(
                      alignment: mine ? AlignmentDirectional.centerEnd
                          : AlignmentDirectional.centerStart,
                      child: Card(
                        color: mine ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: item.giftId == null
                            ? Text(item.text)
                            : Column(mainAxisSize: MainAxisSize.min, children: [
                              if (item.animationUrl?.startsWith('https://') == true)
                                Image.network(item.animationUrl!,
                                  width: 110, height: 95,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.card_giftcard_rounded)),
                              Text('🎁 ${item.giftId}'),
                            ]),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(children: [
            IconButton(
              onPressed: _showGifts,
              tooltip: 'Send Gift',
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
            Expanded(child: TextField(
              controller: _message,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              maxLength: 2000,
              maxLines: 2, minLines: 1,
              decoration: const InputDecoration(
                hintText: 'Message...', counterText: '',
              ),
            )),
            IconButton(
              onPressed: _sending ? null : _sendMessage,
              icon: const Icon(Icons.send_rounded),
            ),
          ]),
        ),
      ])),
    );
  }
}

class _ChatFeedEntry {
  const _ChatFeedEntry({
    required this.id, required this.senderId, required this.text,
    this.time, this.giftId, this.animationUrl,
  });
  final String id;
  final String senderId;
  final String text;
  final DateTime? time;
  final String? giftId;
  final String? animationUrl;
}
