import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/chat_extended_service.dart';
import 'chat_media_bubble.dart';

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
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final data = messages[index].data();
                      final mine = data['senderId'] == uid;
                      final type = (data['type'] ?? 'text').toString();
                      final sender = (data['senderName'] ?? 'Member').toString();
                      final mediaUrl = (data['mediaUrl'] ?? '').toString();
                      return Align(
                        alignment: mine
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        child: Container(
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
                              if (!mine)
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
                                ChatMediaBubble(type: type, url: mediaUrl)
                              else
                                Text((data['text'] ?? '').toString()),
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