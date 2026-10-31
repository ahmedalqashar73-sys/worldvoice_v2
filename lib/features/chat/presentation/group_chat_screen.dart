import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/chat_extended_service.dart';
import 'chat_media_bubble.dart';
import '../services/group_call_service.dart';
import 'group_chat_call_screen.dart';
import 'group_chat_members_sheet.dart';
import 'dart:async';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({
    required this.chatId,
    required this.groupName,
    super.key,
  });

  final String chatId;
  final String groupName;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _text = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ChatExtendedService _service = ChatExtendedService();
  bool _sending = false;
  final GroupCallService _calls = GroupCallService();
  GroupCallInfo? _activeCall;
  Timer? _callRefresh;
  bool _startingCall = false;
  bool _initialMessagesLoaded = false;
  final Set<String> _seenMessageIds = <String>{};

  @override
  void initState() {
    super.initState();
    unawaited(_refreshCall());
    _callRefresh = Timer.periodic(
      const Duration(seconds: 5), (_) => unawaited(_refreshCall()),
    );
  }

  Future<void> _refreshCall() async {
    try {
      final call = await _calls.status(widget.chatId);
      if (mounted) {
        setState(() => _activeCall = call?.isActive == true ? call : null);
      }
    } catch (_) {
      // A temporary call-status failure must never affect group messages.
    }
  }

  Future<void> _startGroupCall(String type) async {
    if (_startingCall) return;
    setState(() => _startingCall = true);
    try {
      final call = await _calls.start(widget.chatId, type);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => GroupChatCallScreen(call: call),
        ),
      );
      await _refreshCall();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _startingCall = false);
    }
  }

  Future<void> _joinGroupCall() async {
    final call = _activeCall;
    if (call == null || _startingCall) return;
    setState(() => _startingCall = true);
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => GroupChatCallScreen(call: call),
        ),
      );
      await _refreshCall();
    } finally {
      if (mounted) setState(() => _startingCall = false);
    }
  }


  Future<void> _sendText() async {
    final value = _text.text.trim();
    if (value.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _service.sendText(chatId: widget.chatId, text: value);
      _text.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickMedia(String type) async {
    XFile? file;
    if (type == 'video') {
      file = await _picker.pickVideo(source: ImageSource.gallery);
    } else {
      file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1800,
      );
    }
    if (file == null || !mounted) return;
    setState(() => _sending = true);
    try {
      await _service.sendMedia(
        chatId: widget.chatId,
        file: File(file.path),
        mediaType: type,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _service.dispose();
    _callRefresh?.cancel();
    _calls.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              child: Icon(Icons.groups_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.groupName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: ar ? 'مكالمة جماعية صوتية' : 'Group voice call',
            onPressed: _startingCall ? null : () => _startGroupCall('audio'),
            icon: const Icon(Icons.call_rounded),
          ),
          IconButton(
            tooltip: ar ? 'مكالمة جماعية فيديو' : 'Group video call',
            onPressed: _startingCall ? null : () => _startGroupCall('video'),
            icon: const Icon(Icons.videocam_rounded),
          ),
          IconButton(
            tooltip: ar ? 'أعضاء المجموعة' : 'Group members',
            onPressed: () => showGroupMembersSheet(context, widget.chatId),
            icon: const Icon(Icons.groups_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            GroupMembersPreview(
              chatId: widget.chatId,
              onTap: () => showGroupMembersSheet(context, widget.chatId),
            ),
            if (_activeCall != null)
              Material(
                color: const Color(0xFF114D3B),
                child: ListTile(
                  leading: Icon(_activeCall!.isVideo
                      ? Icons.video_call_rounded : Icons.call_rounded,
                      color: const Color(0xFF5DE0A9)),
                  title: Text(ar
                      ? 'مكالمة المجموعة جارية • ${_activeCall!.joinedIds.length} متصل'
                      : 'Group call active • ${_activeCall!.joinedIds.length} connected'),
                  trailing: FilledButton(
                    onPressed: _startingCall ? null : _joinGroupCall,
                    child: Text(ar ? 'انضمام' : 'Join'),
                  ),
                ),
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatId)
                    .collection('messages')
                    .orderBy('createdAt', descending: true)
                    .limit(150)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        ar ? 'تعذر تحميل رسائل المجموعة' : 'Group messages unavailable',
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data!.docs;
                  final justArrived = <String>{};
                  if (_initialMessagesLoaded) {
                    for (final message in messages) {
                      if (!_seenMessageIds.contains(message.id)) {
                        justArrived.add(message.id);
                      }
                    }
                  }
                  _seenMessageIds.addAll(messages.map((message) => message.id));
                  _initialMessagesLoaded = true;
                  if (_seenMessageIds.length > 400) {
                    _seenMessageIds
                      ..clear()
                      ..addAll(messages.map((message) => message.id));
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final data = messages[index].data();
                      final mine = data['senderId'] == uid;
                      final type = (data['type'] ?? 'text').toString();
                      final sender = (data['senderName'] ?? 'Member').toString();
                      final photo = (data['senderPhotoUrl'] ?? '').toString().trim();
                      final mediaUrl = (data['mediaUrl'] ?? '').toString();
                      return TweenAnimationBuilder<double>(
                        key: ValueKey('group-message-${messages[index].id}'),
                        tween: Tween<double>(
                          begin: justArrived.contains(messages[index].id) ? 0 : 1,
                          end: 1,
                        ),
                        duration: const Duration(milliseconds: 230),
                        builder: (context, opacity, child) =>
                            Opacity(opacity: opacity, child: child),
                        child: Align(
                          alignment: mine
                              ? AlignmentDirectional.centerEnd
                              : AlignmentDirectional.centerStart,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!mine) ...[
                                _GroupSenderAvatar(photo: photo, name: sender),
                                const SizedBox(width: 6),
                              ],
                              Flexible(child: Container(
                          constraints: const BoxConstraints(maxWidth: 300),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: mine
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  sender,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              if ((type == 'image' || type == 'video') &&
                                  mediaUrl.isNotEmpty)
                                ChatMediaBubble(
                                  type: type,
                                  url: mediaUrl,
                                  fileName: data['fileName']?.toString(),
                                  cacheScope: 'chat_${FirebaseAuth.instance.currentUser?.uid ?? 'anonymous'}',
                                )
                              else
                                Text((data['text'] ?? '').toString()),
                            ],
                          ),
                        )),
                        if (mine) ...[
                          const SizedBox(width: 6),
                          _GroupSenderAvatar(photo: photo, name: sender),
                        ],
                      ],
                    ),
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
                  enabled: !_sending,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  onSelected: (value) {
                    if (value == 'image') _pickMedia('image');
                    if (value == 'video') _pickMedia('video');
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'image',
                      child: ListTile(
                        leading: const Icon(Icons.photo_outlined),
                        title: Text(ar ? 'صورة' : 'Photo'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'video',
                      child: ListTile(
                        leading: const Icon(Icons.videocam_outlined),
                        title: Text(ar ? 'فيديو' : 'Video'),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: TextField(
                    controller: _text,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendText(),
                    decoration: InputDecoration(
                      hintText: ar ? 'رسالة للمجموعة...' : 'Message group...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _sending ? null : _sendText,
                  icon: _sending
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
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
class _GroupSenderAvatar extends StatelessWidget {
  const _GroupSenderAvatar({required this.photo, required this.name});
  final String photo;
  final String name;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 14,
    backgroundColor: const Color(0xFF165B46),
    foregroundImage: photo.isEmpty ? null : NetworkImage(photo),
    child: photo.isEmpty
        ? Text(name.isEmpty ? '?' : name[0].toUpperCase(),
            style: const TextStyle(fontSize: 11))
        : null,
  );
}
