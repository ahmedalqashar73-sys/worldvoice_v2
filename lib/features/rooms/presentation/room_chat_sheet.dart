import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/room_chat_message.dart';
import '../services/room_chat_service.dart';

class RoomChatSheet extends StatefulWidget {
  const RoomChatSheet({
    required this.roomId,
    required this.canModerate,
    super.key,
  });

  final String roomId;
  final bool canModerate;

  @override
  State<RoomChatSheet> createState() => _RoomChatSheetState();
}

class _RoomChatSheetState extends State<RoomChatSheet> {
  late final RoomChatService _service;
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _service = RoomChatService(roomId: widget.roomId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await _service.send(text);
      _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isArabic ? 'دردشة الغرفة' : 'Room chat',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<RoomChatMessage>>(
                stream: _service.watchMessages(),
                builder: (context, snapshot) {
                  final messages = snapshot.data ?? const <RoomChatMessage>[];
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        isArabic
                            ? 'ابدأ أول رسالة في الغرفة.'
                            : 'Start the first room message.',
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final canDelete =
                          widget.canModerate || message.userId == myUid;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        leading: CircleAvatar(
                          backgroundImage:
                              message.photoUrl?.isNotEmpty == true
                                  ? NetworkImage(message.photoUrl!)
                                  : null,
                          child: message.photoUrl?.isNotEmpty == true
                              ? null
                              : const Icon(Icons.person_rounded),
                        ),
                        title: Text(
                          message.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(message.text),
                        trailing: canDelete
                            ? IconButton(
                                tooltip: isArabic ? 'حذف' : 'Delete',
                                onPressed: () => _service.delete(message.id),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 19,
                                ),
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                10,
                12,
                10 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 500,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: isArabic
                            ? 'اكتب رسالة للغرفة...'
                            : 'Message the room...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
