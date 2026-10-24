import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/worldvoice_appearance.dart';
import '../../profile/presentation/public_profile_screen.dart';
import '../../rooms/presentation/unified_gift_panel.dart';
import '../services/chat_call_service.dart';
import '../services/direct_chat_transport.dart';
import '../services/local_chat_store.dart';
import 'chat_call_screen.dart';
import 'chat_media_bubble.dart';
import 'worldvoice_chat_wallpaper.dart';

/// New direct/private chat. The outgoing path NEVER invokes /chat/message
/// or /chat/media: text and files live on devices, not in Cloudinary/Firestore.
class DirectChatConversationScreen extends StatefulWidget {
  const DirectChatConversationScreen({
    required this.chatId, required this.peerId, required this.peerName, super.key,
  });
  final String chatId, peerId, peerName;

  @override
  State<DirectChatConversationScreen> createState() =>
      _DirectChatConversationScreenState();
}

class _DirectChatConversationScreenState
    extends State<DirectChatConversationScreen> {
  final _input = TextEditingController();
  final _recorder = AudioRecorder();
  final _picker = ImagePicker();
  final _callService = ChatCallService();
  LocalChatStore? _store;
  DirectChatTransport? _transport;
  bool _busy = false;
  bool _recording = false;
  bool _blocked = false;
  int _wallpaper = 0;
  String? _setupError;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  DocumentReference<Map<String, dynamic>> get _blockRef =>
      FirebaseFirestore.instance.collection('users').doc(_uid)
        .collection('blocked_peers').doc(widget.peerId);

  @override
  void initState() {
    super.initState();
    unawaited(_setup());
  }

  Future<void> _setup() async {
    if (_uid.isEmpty) return;
    try {
      final store = LocalChatStore.of(_uid, widget.chatId);
      await store.messages();
      final wallpaper = await WorldVoiceChatWallpaper.load(_uid, widget.chatId);
      var blocked = false;
      try {
        blocked = (await _blockRef.get()).exists;
      } catch (error) {
        debugPrint('WorldVoice chat block status unavailable: $error');
      }
      final transport = DirectChatTransport(
        uid: _uid, peerId: widget.peerId, chatId: widget.chatId, store: store);
      if (!mounted) return;
      store.revision.addListener(_refresh);
      setState(() {
        _store = store; _transport = transport;
        _wallpaper = wallpaper; _blocked = blocked;
      });
      if (!blocked) {
        try {
          await transport.start();
        } catch (error) {
          // The local encrypted outbox still works without a live peer.
          if (mounted) setState(() => _setupError = error.toString());
        }
      }
    } catch (error) {
      if (mounted) setState(() => _setupError = error.toString());
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy || _blocked || _transport == null) return;
    setState(() => _busy = true);
    try {
      await _transport!.queueText(text);
      if (mounted) _input.clear();
    } catch (error) { _error(error); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  void _error(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
  }

  Future<void> _pickAttachment(String type) async {
    if (_busy || _blocked || _transport == null) return;
    File? file;
    if (type == 'image') {
      final pick = await _picker.pickImage(source: ImageSource.gallery,
          imageQuality: 85, maxWidth: 1920);
      if (pick != null) file = File(pick.path);
    } else if (type == 'video') {
      final pick = await _picker.pickVideo(source: ImageSource.gallery);
      if (pick != null) file = File(pick.path);
    } else if (type == 'pdf') {
      final pick = await FilePicker.pickFile(
          type: FileType.custom, allowedExtensions: ['pdf']);
      if (pick?.path != null) file = File(pick!.path!);
    }
    if (file == null) return;
    setState(() => _busy = true);
    try { await _transport!.queueMedia(file, type); }
    catch (error) { _error(error); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _toggleRecording() async {
    if (_busy || _transport == null) return;
    if (_recording) {
      setState(() { _recording = false; _busy = true; });
      String? recorded;
      try {
        recorded = await _recorder.stop();
        if (recorded == null) throw StateError('Recording unavailable');
        await _transport!.queueMedia(File(recorded), 'audio');
      } catch (error) { _error(error); }
      finally {
        if (recorded != null) {
          try { await File(recorded).delete(); } catch (_) {}
        }
        if (mounted) setState(() => _busy = false);
      }
    } else {
      try {
        if (!await _recorder.hasPermission()) {
          throw StateError('Microphone permission required');
        }
        final root = await getTemporaryDirectory();
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
          path: '${root.path}/wv_voice_${DateTime.now().microsecondsSinceEpoch}.m4a');
        if (mounted) setState(() => _recording = true);
      } catch (error) { _error(error); }
    }
  }

  Future<void> _call(String type) async {
    try {
      final info = await _callService.startCall(
        recipientId: widget.peerId, chatId: widget.chatId, type: type);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ChatCallScreen(call: info, peerName: widget.peerName, peerPhotoUrl: '', accepted: false)));
    } catch (error) { _error(error); }
  }

  Future<void> _chooseWallpaper() async {
    await showWorldVoiceWallpaperPicker(context, selected: _wallpaper,
      onSelected: (value) {
        setState(() => _wallpaper = value);
        unawaited(WorldVoiceChatWallpaper.save(_uid, widget.chatId, value));
      });
  }

  Future<void> _chooseAppearance() async {
    final current = WorldVoiceAppearance.instance.mode.value;
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: const Color(0xFF1C2228),
      showDragHandle: true,
      builder: (sheetContext) => Theme(
        data: ThemeData.dark(useMaterial3: true),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(_ar ? 'مظهر WorldVoice' : 'WorldVoice appearance'),
                subtitle: Text(_ar
                    ? 'اختر الوضع الداكن أو الفاتح أو حسب الجهاز'
                    : 'Choose Dark, Light, or Follow device'),
              ),
              for (final mode in ThemeMode.values)
                ListTile(
                  leading: Icon(
                    mode == current
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: mode == current
                        ? const Color(0xFF68D3AA) : Colors.white70,
                  ),
                  title: Text(switch (mode) {
                    ThemeMode.dark => _ar ? 'داكن' : 'Dark',
                    ThemeMode.light => _ar ? 'فاتح' : 'Light',
                    ThemeMode.system => _ar ? 'حسب الجهاز' : 'Follow device',
                  }),
                  onTap: () => Navigator.of(sheetContext).pop(mode),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) {
      await WorldVoiceAppearance.instance.setMode(selected);
    }
  }

  Future<void> _toggleBlock() async {
    try {
      if (_blocked) {
        await _blockRef.delete();
      } else {
        await _blockRef.set({
          'targetId': widget.peerId, 'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) {
        setState(() => _blocked = !_blocked);
        if (_blocked) {
          unawaited(_transport?.dispose());
          _transport = null;
        } else {
          final store = _store;
          if (store != null) {
            final transport = DirectChatTransport(
              uid: _uid, peerId: widget.peerId, chatId: widget.chatId, store: store);
            _transport = transport;
            unawaited(transport.start());
          }
        }
      }
    } catch (error) { _error(error); }
  }

  Future<void> _report() async {
    final reason = await showModalBottomSheet<String>(context: context,
      builder: (ctx) => SafeArea(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in [
            ('harassment', 'مضايقة / Harassment'),
            ('spam', 'رسائل مزعجة / Spam'),
            ('impersonation', 'انتحال شخصية / Impersonation'),
            ('other', 'سبب آخر / Other'),
          ])
            ListTile(title: Text(entry.$2),
              onTap: () => Navigator.pop(ctx, entry.$1)),
        ],
      )));
    if (reason == null) return;
    try {
      await FirebaseFirestore.instance.collection('chat_reports').add({
        'reporterId': _uid, 'targetUserId': widget.peerId,
        'chatId': widget.chatId, 'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_ar ? 'تم إرسال البلاغ.' : 'Report submitted.')));
      }
    } catch (error) { _error(error); }
  }

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_ar ? 'حذف المحادثة من جهازك؟' : 'Delete local conversation?'),
        content: Text(_ar
            ? 'سيتم حذف رسائلك المحلية هنا فقط، ولن تُحذف من هاتف الطرف الآخر.'
            : 'Your local messages will be deleted, not the other person’s copy.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text(_ar ? 'إلغاء' : 'Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text(_ar ? 'حذف' : 'Delete')),
        ]));
    if (confirm != true) return;
    try { await _store?.clear(); } catch (error) { _error(error); }
  }

  Future<void> _options() async {
    await showModalBottomSheet<void>(
      context: context, showDragHandle: true, useSafeArea: true,
      backgroundColor: const Color(0xFF1C2228),
      builder: (sheet) => Theme(
        data: ThemeData.dark(useMaterial3: true),
        child: SafeArea(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.person_outline),
            title: Text(_ar ? 'الملف الشخصي' : 'View profile'),
            onTap: () {
              Navigator.pop(sheet);
              Navigator.push(context, MaterialPageRoute<void>(
                builder: (_) => PublicProfileScreen(
                  userId: widget.peerId,
                  languageCode: Localizations.localeOf(context).languageCode)));
            }),
          ListTile(leading: const Icon(Icons.wallpaper_rounded),
            title: Text(_ar ? 'خلفية المحادثة' : 'Chat wallpaper'),
            onTap: () { Navigator.pop(sheet); unawaited(_chooseWallpaper()); }),
          ListTile(leading: const Icon(Icons.dark_mode_outlined),
            title: Text(_ar ? 'مظهر WorldVoice' : 'WorldVoice appearance'),
            onTap: () { Navigator.pop(sheet); unawaited(_chooseAppearance()); }),
          ListTile(leading: Icon(_blocked ? Icons.lock_open : Icons.block),
            title: Text(_blocked
                ? (_ar ? 'إلغاء الحظر' : 'Unblock')
                : (_ar ? 'حظر المستخدم' : 'Block user')),
            onTap: () { Navigator.pop(sheet); unawaited(_toggleBlock()); }),
          ListTile(leading: const Icon(Icons.flag_outlined),
            title: Text(_ar ? 'إبلاغ' : 'Report user'),
            onTap: () { Navigator.pop(sheet); unawaited(_report()); }),
          ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: Text(_ar ? 'حذف المحادثة من جهازي' : 'Delete local chat'),
            onTap: () { Navigator.pop(sheet); unawaited(_clearChat()); }),
        ]))));
  }

  Future<void> _messageOptions(Map<String, dynamic> item) async {
    final mine = item['senderId'] == _uid;
    final legacy = item['legacy'] == true;
    final id = item['id']?.toString() ?? '';
    final withdrawn = item['withdrawn'] == true;
    if (id.isEmpty) return;
    final action = await showModalBottomSheet<String>(context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(child: Column(
        mainAxisSize: MainAxisSize.min, children: [
          if (!withdrawn && item['type'] == 'text')
            ListTile(leading: const Icon(Icons.copy),
              title: Text(_ar ? 'نسخ' : 'Copy'),
              onTap: () => Navigator.pop(ctx, 'copy')),
          if (mine && !legacy && !withdrawn && item['type'] == 'text')
            ListTile(leading: const Icon(Icons.edit_outlined),
              title: Text(_ar ? 'تعديل الرسالة' : 'Edit message'),
              onTap: () => Navigator.pop(ctx, 'edit')),
          ListTile(leading: const Icon(Icons.delete_outline),
            title: Text(_ar ? 'حذف لدي' : 'Delete for me'),
            onTap: () => Navigator.pop(ctx, 'hide')),
          if (mine && !legacy && !withdrawn)
            ListTile(leading: const Icon(Icons.undo, color: Colors.red),
              title: Text(_ar ? 'سحب للجميع' : 'Unsend for everyone'),
              onTap: () => Navigator.pop(ctx, 'withdraw')),
        ])));
    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: item['text']?.toString() ?? ''));
    } else if (action == 'hide') {
      if (legacy) {
        // Read-only pre-migration entry; keep a device-only suppression record.
        await _store?.upsert({
          'id': id, 'senderId': item['senderId'], 'type': 'legacy_hidden',
          'text': '', 'createdAt': item['createdAt'], 'hidden': true,
          'delivered': true,
        });
      } else {
        await _store?.hide(id);
      }
    } else if (action == 'withdraw') {
      await _transport?.withdraw(id);
    } else if (action == 'edit' && mounted) {
      final controller = TextEditingController(text: item['text']?.toString() ?? '');
      final edited = await showDialog<String>(
        context: context, builder: (ctx) => AlertDialog(
          title: Text(_ar ? 'تعديل الرسالة' : 'Edit message'),
          content: TextField(controller: controller, maxLines: 4, autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(_ar ? 'إلغاء' : 'Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(_ar ? 'حفظ' : 'Save')),
          ]));
      controller.dispose();
      if (edited != null && edited.isNotEmpty) {
        await _transport?.edit(id, edited);
      }
    }
  }

  void _gifts() {
    showModalBottomSheet<void>(context: context, isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: UnifiedGiftPanel(
          contextType: 'chat', contextId: widget.chatId,
          recipients: {widget.peerId: widget.peerName},
        )));
  }

  @override
  void dispose() {
    _store?.revision.removeListener(_refresh);
    unawaited(_transport?.dispose());
    unawaited(_recorder.dispose());
    _callService.dispose();
    _input.dispose();
    super.dispose();
  }

  Widget _bubble(Map<String, dynamic> item) {
    if (item['hidden'] == true) return const SizedBox.shrink();
    final mine = item['senderId'] == _uid;
    final removed = item['withdrawn'] == true;
    final type = item['type']?.toString() ?? 'text';
    final text = item['text']?.toString() ?? '';
    final edited = item['edited'] == true;
    final read = item['read'] == true;
    final created = DateTime.fromMillisecondsSinceEpoch(
      (item['createdAt'] as num?)?.toInt() ?? 0);
    final time = TimeOfDay.fromDateTime(created).format(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final myBubble = dark ? const Color(0xFF145540) : const Color(0xFFD6F0E3);
    final peerBubble = dark ? const Color(0xF02A3038) : const Color(0xFFF8FCFA);
    final messageColor = dark ? const Color(0xFFF2F7F4) : const Color(0xFF16372B);
    final detailColor = dark ? const Color(0xFFBACEC5) : const Color(0xFF657D72);
    return Align(
      alignment: mine ? AlignmentDirectional.centerEnd :
        AlignmentDirectional.centerStart,
      child: GestureDetector(
        onLongPress: () => unawaited(_messageOptions(item)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 305),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
          decoration: BoxDecoration(
            color: mine ? myBubble : peerBubble,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0x110E2B22),
              blurRadius: 5, offset: Offset(0, 2))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (removed)
                Text(_ar ? 'تم سحب الرسالة' : 'Message unsent',
                  style: TextStyle(color: detailColor,
                    fontStyle: FontStyle.italic))
              else if (type == 'gift')
                Text(text.isNotEmpty ? text : '🎁 WorldVoice Gift',
                  style: TextStyle(
                    color: messageColor, fontWeight: FontWeight.w700))
              else if (type != 'text')
                _PrivateMediaBubble(
                  type: type,
                  path: item['filePath']?.toString() ?? '',
                  name: item['fileName']?.toString() ?? '',
                  legacyUrl: item['mediaUrl']?.toString() ?? '',
                  cacheScope: 'chat_$_uid',
                )
              else
                Text(text, style: TextStyle(
                  fontSize: 15, height: 1.4, color: messageColor)),
              const SizedBox(height: 5),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (edited) ...[
                  Text(_ar ? 'معدلة' : 'Edited',
                    style: TextStyle(fontSize: 10, color: detailColor)),
                  const SizedBox(width: 5),
                ],
                Text(time, style: TextStyle(
                  fontSize: 10, color: detailColor)),
                if (mine) ...[
                  const SizedBox(width: 5),
                  Text(read
                    ? (_ar ? 'تمت القراءة' : 'Read')
                    : (_ar ? 'تم الإرسال' : 'Sent'),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                      color: read
                          ? (dark ? const Color(0xFF91E5C1) : const Color(0xFF11845C))
                          : detailColor)),
                ],
              ]),
            ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? const Color(0xFFF1F6F3) : const Color(0xFF183A2C);
    final barColor = dark ? const Color(0xFF171B20) : const Color(0xFFFBFDFB);
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0F1115) : const Color(0xFFF4F6F5),
      appBar: AppBar(
        titleSpacing: 0,
        foregroundColor: foreground,
        backgroundColor: barColor,
        title: InkWell(
          onTap: _options,
          child: Row(children: [
            const CircleAvatar(
              radius: 18, backgroundColor: Color(0xFF204E3C),
              child: Icon(Icons.person, color: Color(0xFFAFEBD0))),
            const SizedBox(width: 9),
            Flexible(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.peerName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(_ar ? 'محادثة WorldVoice الخاصة' : 'WorldVoice private chat',
                  style: TextStyle(fontSize: 11,
                    color: foreground.withValues(alpha: .64))),
              ])),
          ]),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call_outlined),
            onPressed: () => unawaited(_call('audio'))),
          IconButton(icon: const Icon(Icons.videocam_outlined),
            onPressed: () => unawaited(_call('video'))),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: _options),
        ],
      ),
      body: WorldVoiceChatWallpaper(index: _wallpaper,
        child: Column(children: [
          if (_setupError != null)
            Padding(padding: const EdgeInsets.all(8),
              child: Text(_setupError!, style: const TextStyle(color: Colors.red))),
          if (_blocked)
            Padding(padding: const EdgeInsets.all(8),
              child: Text(_ar ? 'هذا المستخدم محظور' : 'This user is blocked')),
          Expanded(child: _store == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                // Read-only legacy history until the safe migration runs.
                // New direct chat messages never write to this collection.
                stream: FirebaseFirestore.instance.collection('chats')
                  .doc(widget.chatId).collection('messages')
                  .orderBy('createdAt', descending: true).limit(100).snapshots(),
                builder: (ctx, giftSnapshot) =>
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _store!.messages(),
                    builder: (ctx, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text(snapshot.error.toString()));
                      }
                      final messages = List<Map<String, dynamic>>.from(
                        snapshot.data ?? const <Map<String, dynamic>>[]);
                      // Preserve historical chats while keeping them read-only.
                      final locallyHiddenIds = messages.where((m) =>
                        m['type'] == 'legacy_hidden').map((m) => m['id']).toSet();
                      messages.removeWhere((m) =>
                        m['type'] == 'legacy_hidden' || m['hidden'] == true);
                      for (final doc in giftSnapshot.data?.docs ??
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
                        if (locallyHiddenIds.contains(doc.id) ||
                            messages.any((m) => m['id'] == doc.id)) {
                          continue;
                        }
                        final data = doc.data();
                        final timestamp = data['createdAt'];
                        messages.add({
                          ...data,
                          'id': doc.id, 'legacy': true,
                          'type': data['type'] ?? 'text',
                          'senderId': data['senderId'],
                          'text': data['type'] == 'gift'
                            ? '🎁 ${data['senderName'] ?? 'WorldVoice'}'
                            : (data['text'] ?? '').toString(),
                          'createdAt': timestamp is Timestamp
                              ? timestamp.millisecondsSinceEpoch : 0,
                          'hidden': false,
                        });
                      }
                      messages.sort((a, b) =>
                        ((a['createdAt'] as num?)?.toInt() ?? 0).compareTo(
                          (b['createdAt'] as num?)?.toInt() ?? 0));
                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.only(top: 10, bottom: 14),
                        itemCount: messages.length,
                        itemBuilder: (ctx, index) =>
                          _bubble(messages[messages.length - 1 - index]),
                      );
                    }))),
          Container(
            decoration: BoxDecoration(
              color: barColor,
              boxShadow: const [BoxShadow(
                color: Color(0x1F000000), blurRadius: 9)]),
            padding: const EdgeInsets.fromLTRB(6, 5, 6, 8),
            child: SafeArea(top: false, child: Row(children: [
              PopupMenuButton<String>(
                tooltip: _ar ? 'إرفاق' : 'Attach',
                icon: Icon(Icons.add_circle_outline, color: foreground),
                onSelected: (type) {
                  if (type == 'gift') { _gifts(); return; }
                  unawaited(_pickAttachment(type));
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'image', child: Text(_ar ? 'صورة' : 'Photo')),
                  PopupMenuItem(value: 'video', child: Text(_ar ? 'فيديو' : 'Video')),
                  PopupMenuItem(value: 'pdf', child: Text('PDF')),
                  PopupMenuItem(value: 'gift', child: Text(_ar ? 'هدية' : 'Gift')),
                ]),
              Expanded(child: TextField(
                controller: _input, enabled: !_blocked,
                minLines: 1, maxLines: 4,
                style: TextStyle(color: foreground, fontSize: 15),
                cursorColor: const Color(0xFF59CFA3),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => unawaited(_send()),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: dark
                    ? const Color(0xFF262C32) : const Color(0xFFECF2EE),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15, vertical: 12),
                  hintText: _ar ? 'اكتب رسالة...' : 'Message...',
                  hintStyle: TextStyle(
                    color: foreground.withValues(alpha: .53)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  )))),
              IconButton(
                tooltip: _recording ? 'Send voice' : 'Record voice',
                onPressed: _busy || _blocked ? null : _toggleRecording,
                icon: Icon(_recording
                    ? Icons.stop_circle_rounded : Icons.mic_none_rounded,
                    color: _recording ? Colors.redAccent
                        : (dark ? const Color(0xFF8ED5B7) : const Color(0xFF286B51)))),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF169B6B),
                  foregroundColor: Colors.white,
                ),
                onPressed: _busy || _blocked ? null : _send,
                icon: _busy
                  ? const SizedBox.square(dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded)),
            ])),
          ),
        ])),
    );
  }
}

class _PrivateMediaBubble extends StatefulWidget {
  const _PrivateMediaBubble({required this.type, required this.path,
    required this.name, required this.legacyUrl, required this.cacheScope});
  final String type, path, name, legacyUrl, cacheScope;
  @override
  State<_PrivateMediaBubble> createState() => _PrivateMediaBubbleState();
}

class _PrivateMediaBubbleState extends State<_PrivateMediaBubble> {
  VideoPlayerController? _video;
  AudioPlayer? _audio;

  Future<void> _play() async {
    final file = File(widget.path);
    if (!await file.exists()) return;
    try {
      if (widget.type == 'video') {
        _video ??= VideoPlayerController.file(file);
        await _video!.initialize();
        await _video!.play();
      } else if (widget.type == 'audio') {
        _audio ??= AudioPlayer();
        await _audio!.setFilePath(file.path);
        await _audio!.play();
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _video?.dispose();
    _audio?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.path.isEmpty && widget.legacyUrl.isNotEmpty) {
      return ChatMediaBubble(
        type: widget.type, url: widget.legacyUrl,
        cacheScope: widget.cacheScope, fileName: widget.name);
    }
    if (widget.type == 'image') {
      return ClipRRect(borderRadius: BorderRadius.circular(13),
        child: Image.file(File(widget.path), width: 220,
          height: 220, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image)));
    }
    if (widget.type == 'video' && _video?.value.isInitialized == true) {
      return GestureDetector(onTap: _play, child: SizedBox(
        width: 230, height: 180,
        child: AspectRatio(aspectRatio: _video!.value.aspectRatio,
          child: VideoPlayer(_video!))));
    }
    return InkWell(onTap: _play,
      child: SizedBox(width: 205,
        child: Row(children: [
          Icon(widget.type == 'video' ? Icons.play_circle :
            widget.type == 'audio' ? Icons.play_arrow :
            Icons.picture_as_pdf_rounded, color: const Color(0xFF267453)),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.name.isEmpty
            ? widget.type : widget.name,
            maxLines: 2, overflow: TextOverflow.ellipsis)),
        ])));
  }
}
