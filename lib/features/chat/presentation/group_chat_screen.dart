import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../services/chat_extended_service.dart';
import 'chat_media_bubble.dart';
import '../services/group_call_service.dart';
import 'group_chat_call_screen.dart';
import 'group_chat_members_sheet.dart';
import 'worldvoice_chat_wallpaper.dart';
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
  final AudioRecorder _voiceRecorder = AudioRecorder();
  bool _recordingVoice = false;
  final GroupCallService _calls = GroupCallService();
  GroupCallInfo? _activeCall;
  Timer? _callRefresh;
  bool _startingCall = false;
  bool _initialMessagesLoaded = false;
  final Set<String> _seenMessageIds = <String>{};
  int _wallpaper = WorldVoiceChatWallpaper.none;
  String? _replacingAudioMessageId;
  bool _canModerateMessages = false;
  late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> _groupUpdates;

  @override
  void initState() {
    super.initState();
    unawaited(_loadWallpaper());
    _groupUpdates = FirebaseFirestore.instance.collection('chats')
        .doc(widget.chatId).snapshots().listen((snapshot) {
      final data = snapshot.data() ?? const <String, dynamic>{};
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final moderators = (data['moderatorIds'] as List?) ?? const [];
      final value = uid != null &&
          (data['ownerId'] == uid || moderators.contains(uid));
      if (mounted && value != _canModerateMessages) {
        setState(() => _canModerateMessages = value);
      }
    }, onError: (Object _) {});
    unawaited(_refreshCall());
    _callRefresh = Timer.periodic(
      const Duration(seconds: 5), (_) => unawaited(_refreshCall()),
    );
  }


  Future<void> _loadWallpaper() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final value = await WorldVoiceChatWallpaper.load(uid, widget.chatId);
    if (mounted) setState(() => _wallpaper = value);
  }

  Future<void> _pickWallpaper() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await showWorldVoiceWallpaperPicker(context,
      selected: _wallpaper,
      onSelected: (value) {
        if (!mounted) return;
        setState(() => _wallpaper = value);
        unawaited(WorldVoiceChatWallpaper.save(uid, widget.chatId, value));
      });
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error.toString().replaceFirst('Bad state: ', ''))));
  }

  Future<void> _editMessage(String id, String existing) async {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final controller = TextEditingController(text: existing);
    try {
      final value = await showDialog<String>(context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ar ? 'تعديل الرسالة' : 'Edit message'),
          content: TextField(
            key: const ValueKey('group-message-edit-input'),
            controller: controller, autofocus: true, maxLength: 1500,
            minLines: 1, maxLines: 5,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(ar ? 'إلغاء' : 'Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(ar ? 'حفظ' : 'Save')),
          ],
        ));
      if (value == null || value.isEmpty || value == existing) return;
      await _service.manageGroupMessage(
        chatId: widget.chatId, messageId: id, action: 'edit', text: value);
    } catch (error) {
      _showError(error);
    } finally {
      controller.dispose();
    }
  }

  Future<void> _deleteMessage(String id) async {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final confirmed = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ar ? 'حذف الرسالة للجميع؟' : 'Delete message for everyone?'),
        content: Text(ar ? 'سيختفي النص أو التسجيل من محادثة المجموعة.'
                         : 'The message or voice clip will disappear from the group.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text(ar ? 'إلغاء' : 'Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text(ar ? 'حذف' : 'Delete')),
        ],
      ));
    if (confirmed != true || !mounted) return;
    try {
      await _service.manageGroupMessage(
        chatId: widget.chatId, messageId: id, action: 'delete');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _showMessageOptions(
      String id, Map<String, dynamic> message, bool mine) async {
    if (message['deleted'] == true || (!mine && !_canModerateMessages)) return;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final type = (message['type'] ?? 'text').toString();
    final action = await showModalBottomSheet<String>(context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (mine && type == 'text')
            ListTile(key: const ValueKey('group-edit-message'),
              leading: const Icon(Icons.edit_outlined),
              title: Text(ar ? 'تعديل الرسالة' : 'Edit message'),
              onTap: () => Navigator.pop(ctx, 'edit')),
          if (mine && type == 'audio')
            ListTile(key: const ValueKey('group-replace-voice'),
              leading: const Icon(Icons.mic_rounded),
              title: Text(ar ? 'إعادة تسجيل الرسالة الصوتية' : 'Replace voice recording'),
              onTap: () => Navigator.pop(ctx, 'replace_audio')),
          if (mine || _canModerateMessages)
            ListTile(key: const ValueKey('group-delete-message'),
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text(ar ? 'حذف الرسالة للجميع' : 'Delete for everyone'),
              onTap: () => Navigator.pop(ctx, 'delete')),
        ]),
      ));
    if (!mounted) return;
    if (action == 'edit') {
      await _editMessage(id, (message['text'] ?? '').toString());
    } else if (action == 'delete') {
      await _deleteMessage(id);
    } else if (action == 'replace_audio') {
      if (_sending || _recordingVoice) {
        _showError(StateError(ar ? 'أنهِ التسجيل الحالي أولًا'
                                  : 'Finish the current recording first.'));
        return;
      }
      setState(() => _replacingAudioMessageId = id);
      await _toggleVoice();
    }
  }

  Future<void> _cancelVoice() async {
    String? path;
    try {
      path = await _voiceRecorder.stop();
    } catch (error) {
      _showError(error);
    } finally {
      if (path != null) {
        try { await File(path).delete(); } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _recordingVoice = false;
          _replacingAudioMessageId = null;
        });
      }
    }
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

  Future<void> _toggleVoice() async {
    if (_sending) return;
    if (_recordingVoice) {
      setState(() { _recordingVoice = false; _sending = true; });
      String? path;
      try {
        path = await _voiceRecorder.stop();
        if (path == null || path.isEmpty) throw StateError('تعذر حفظ التسجيل الصوتي.');
        final replacementId = _replacingAudioMessageId;
        if (replacementId == null) {
          await _service.sendMedia(
            chatId: widget.chatId, file: File(path), mediaType: 'audio');
        } else {
          await _service.replaceGroupVoiceMessage(
            chatId: widget.chatId, messageId: replacementId, file: File(path));
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
        }
      } finally {
        if (path != null) { try { await File(path).delete(); } catch (_) {} }
        if (mounted) setState(() {
          _sending = false;
          _replacingAudioMessageId = null;
        });
      }
      return;
    }
    try {
      if (!await _voiceRecorder.hasPermission()) {
        throw StateError('اسمح للتطبيق باستخدام الميكروفون.');
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/wv_group_voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
      await _voiceRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
        path: path);
      if (mounted) setState(() => _recordingVoice = true);
    } catch (error) {
      if (mounted) {
        setState(() => _replacingAudioMessageId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
      }
    }
  }

  Future<void> _handleGroupAction(String action) async {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    if (action == 'delete_group' || action == 'leave') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(action == 'delete_group'
            ? (ar ? 'حذف المجموعة للجميع؟' : 'Delete group for everyone?')
            : (ar ? 'مغادرة المجموعة؟' : 'Leave group?')),
          content: Text(action == 'delete_group'
            ? (ar ? 'لن يتمكن الأعضاء من الوصول لمحادثة المجموعة بعد الحذف.'
                  : 'Members will no longer access this group.')
            : (ar ? 'لن تصلك رسائل المجموعة بعد المغادرة.'
                  : 'You will stop receiving group messages.')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(ar ? 'إلغاء' : 'Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text(ar ? 'تأكيد' : 'Confirm')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    try {
      await _service.manageGroup(chatId: widget.chatId, action: action);
      if (!mounted) return;
      if (action == 'delete_group' || action == 'delete_for_me' ||
          action == 'leave') {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
      }
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
    if (_recordingVoice) unawaited(_voiceRecorder.stop());
    unawaited(_voiceRecorder.dispose());
    _callRefresh?.cancel();
    unawaited(_groupUpdates.cancel());
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
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('chats')
                .doc(widget.chatId).snapshots(),
            builder: (context, snap) {
              final data = snap.data?.data() ?? const <String, dynamic>{};
              final owner = data['ownerId'] == uid;
              final canManage = owner ||
                ((data['moderatorIds'] as List?) ?? const []).contains(uid);
              return PopupMenuButton<String>(
                key: const ValueKey('group-settings-menu'),
                tooltip: ar ? 'إدارة المجموعة' : 'Group settings',
                onSelected: (action) {
                  if (action == 'members') {
                    showGroupMembersSheet(context, widget.chatId);
                  } else if (action == 'invite') {
                    showGroupInvitePicker(context, widget.chatId);
                  } else if (action == 'wallpaper') {
                    _pickWallpaper();
                  } else { _handleGroupAction(action); }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'members',
                    child: Text(ar ? 'الأعضاء وإضافة أصدقاء' : 'Members and add friends')),
                  if (canManage) PopupMenuItem(value: 'invite',
                    child: Text(ar ? 'إضافة أشخاص للمجموعة' : 'Add people to group')),
                  PopupMenuItem(value: 'wallpaper',
                    child: Text(ar ? 'تغيير خلفية المجموعة' : 'Change group wallpaper')),
                  PopupMenuItem(value: 'delete_for_me',
                    child: Text(ar ? 'حذف المجموعة من عندي' : 'Remove group from my chats')),
                  if (!owner) PopupMenuItem(value: 'leave',
                    child: Text(ar ? 'الخروج من المجموعة' : 'Leave group')),
                  if (owner) PopupMenuItem(value: 'delete_group',
                    child: Text(ar ? 'حذف المجموعة للجميع' : 'Delete group for everyone',
                      style: const TextStyle(color: Colors.redAccent))),
                ],
                icon: const Icon(Icons.more_vert_rounded),
              );
            },
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
              child: WorldVoiceChatWallpaper(
                index: _wallpaper,
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
                      final messageId = messages[index].id;
                      final deleted = data['deleted'] == true || type == 'deleted';
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
                              Flexible(child: GestureDetector(
                          onLongPress: deleted || (!mine && !_canModerateMessages)
                              ? null : () => _showMessageOptions(messageId, data, mine),
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
                              Row(children: [
                                Expanded(child: Text(sender,
                                  style: const TextStyle(fontSize: 11,
                                    fontWeight: FontWeight.w900))),
                                if (!deleted && (mine || _canModerateMessages))
                                  InkWell(
                                    key: ValueKey('group-message-menu-$messageId'),
                                    onTap: () => _showMessageOptions(messageId, data, mine),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.more_horiz_rounded, size: 19),
                                    ),
                                  ),
                              ]),
                              const SizedBox(height: 4),
                              if (deleted)
                                Text(ar ? 'تم حذف الرسالة' : 'Message deleted',
                                  style: const TextStyle(fontStyle: FontStyle.italic))
                              else if (const ['image', 'video', 'audio', 'pdf']
                                    .contains(type) && mediaUrl.isNotEmpty)
                                ChatMediaBubble(
                                  type: type,
                                  url: mediaUrl,
                                  fileName: data['fileName']?.toString(),
                                  cacheScope: 'chat_${FirebaseAuth.instance.currentUser?.uid ?? 'anonymous'}',
                                )
                              else
                                Text((data['text'] ?? '').toString()),
                              if (!deleted && data['edited'] == true)
                                Padding(padding: const EdgeInsets.only(top: 3),
                                  child: Text(ar ? 'معدلة' : 'Edited',
                                    style: const TextStyle(fontSize: 10,
                                      fontStyle: FontStyle.italic))),
                            ],
                          ),
                        ))),
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
            ),
            if (_replacingAudioMessageId != null)
              Padding(padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(ar ? 'تسجيل بديل للرسالة الصوتية الحالية'
                               : 'Recording a replacement voice message',
                  style: Theme.of(context).textTheme.labelSmall)),
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
                if (_recordingVoice)
                  IconButton(
                    key: const ValueKey('group-cancel-voice-record'),
                    tooltip: ar ? 'إلغاء التسجيل' : 'Cancel recording',
                    onPressed: _sending ? null : _cancelVoice,
                    icon: const Icon(Icons.close_rounded),
                  ),
                IconButton(
                  key: const ValueKey('group-voice-record'),
                  tooltip: _recordingVoice
                      ? (_replacingAudioMessageId != null
                         ? (ar ? 'حفظ التسجيل البديل' : 'Save replacement recording')
                         : (ar ? 'إرسال التسجيل الصوتي' : 'Send voice message'))
                      : (ar ? 'تسجيل رسالة صوتية' : 'Record voice message'),
                  onPressed: _sending ? null : _toggleVoice,
                  icon: Icon(_recordingVoice
                      ? Icons.stop_circle_rounded : Icons.mic_rounded,
                      color: _recordingVoice ? Colors.redAccent : null),
                ),
                IconButton.filledTonal(
                  onPressed: _sending || _recordingVoice ? null : _sendText,
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
