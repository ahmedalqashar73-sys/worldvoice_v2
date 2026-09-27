import 'package:flutter/material.dart';
import '../data/room_chat_message.dart';

/// Live room conversation, independent of Firebase for layout testing.
class RoomConversationPanel extends StatefulWidget {
  const RoomConversationPanel({
    required this.messages, required this.onSend, required this.isArabic,
    required this.onGifts, required this.onShop, required this.onTools,
    required this.onCaptions, required this.onMic, required this.micIcon,
    required this.micLabel, this.enabled = true, this.bottomControl,
    this.showMic = true, super.key,
  });
  final Stream<List<RoomChatMessage>> messages;
  final Future<void> Function(String) onSend;
  final bool isArabic;
  final bool enabled;
  final Widget? bottomControl;
  final bool showMic;
  final VoidCallback onGifts, onShop, onTools, onCaptions;
  final VoidCallback? onMic;
  final IconData micIcon;
  final String micLabel;
  @override
  State<RoomConversationPanel> createState() => _RoomConversationPanelState();
}

class _RoomConversationPanelState extends State<RoomConversationPanel> {
  final _text = TextEditingController();
  bool _sending = false;
  // Do not animate historical messages on first entry or move the room when a
  // new chat arrives; only the new message bubble fades in.
  final Set<String> _seenMessageIds = <String>{};
  final Set<String> _pendingMessageAnimations = <String>{};
  bool _initialMessagesLoaded = false;
  @override
  void dispose() { _text.dispose(); super.dispose(); }
  Future<void> _send() async {
    final value = _text.text.trim();
    if (value.isEmpty || _sending || !widget.enabled) return;
    setState(() => _sending = true);
    try {
      await widget.onSend(value);
      if (mounted && _text.text.trim() == value) _text.clear();
    } catch (_) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.isArabic ? 'تعذر إرسال الرسالة. حاول مجددًا.' : 'Message not sent. Please retry.'),
      )); }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
  Widget _action(IconData icon, String label, VoidCallback? tap, {Color color = Colors.white}) {
    return IconButton(
      tooltip: label, onPressed: tap,
      style: IconButton.styleFrom(backgroundColor: const Color(0xFF123C30),
        minimumSize: const Size(40, 44), padding: const EdgeInsets.all(8)),
      icon: Icon(icon, size: 21, color: tap == null ? Colors.white38 : color),
    );
  }
  @override
  Widget build(BuildContext context) {
    final ar = widget.isArabic;
    return Column(children: [
      Expanded(child: StreamBuilder<List<RoomChatMessage>>(
        stream: widget.messages,
        builder: (context, snapshot) {
          if (snapshot.hasError) { return Center(child: Text(
            ar ? 'تعذر تحميل الرسائل' : 'Could not load messages',
            style: const TextStyle(color: Colors.white70))); }
          final messages = snapshot.data ?? const <RoomChatMessage>[];
          if (snapshot.hasData) {
            if (_initialMessagesLoaded) {
              for (final message in messages) {
                if (!_seenMessageIds.contains(message.id)) {
                  _pendingMessageAnimations.add(message.id);
                }
              }
            }
            _seenMessageIds.addAll(messages.map((message) => message.id));
            _initialMessagesLoaded = true;
            if (_seenMessageIds.length > 400) {
              _pendingMessageAnimations.removeWhere(
                  (id) => !messages.any((msg) => msg.id == id));
              _seenMessageIds
                ..clear()
                ..addAll(messages.map((message) => message.id));
            }
          }
          return ListView.builder(
            key: const PageStorageKey<String>('worldvoice-room-chat-only'),
            primary: false,
            reverse: true, padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: messages.length + 1,
            itemBuilder: (context, index) {
              final welcome = index == messages.length;
              final msg = welcome ? null : messages[index];
              final bubble = Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(color: const Color(0xFF102C25).withValues(alpha: .8),
                    borderRadius: BorderRadius.circular(16)),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: welcome ? 'WorldVoice  ' : '${msg!.displayName}  ',
                      style: const TextStyle(color: Color(0xFFE7C56E), fontWeight: FontWeight.w700)),
                    TextSpan(text: welcome
                      ? (ar ? 'أهلًا بك! تعلّم وتحدث وشارك باحترام.' : 'Welcome! Learn, talk and share with respect.')
                      : msg!.text),
                  ]), style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
                ),
              );
              // Fade the words of each NEW message only. The seats, Teacher AI
              // and chat viewport stay fixed on arrival.
              if (msg != null && _pendingMessageAnimations.contains(msg.id)) {
                return TweenAnimationBuilder<double>(
                  key: ValueKey<String>('new-message-${msg.id}'),
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 260),
                  onEnd: () => _pendingMessageAnimations.remove(msg.id),
                  builder: (context, value, child) =>
                      Opacity(opacity: value, child: child),
                  child: bubble,
                );
              }
              return bubble;
            },
          );
        },
      )),
      if (widget.bottomControl != null && MediaQuery.viewInsetsOf(context).bottom == 0)
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
          child: widget.bottomControl),
      Padding(
        key: const ValueKey('room-composer'),
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: LayoutBuilder(builder: (context, constraints) {
          final typing = MediaQuery.viewInsetsOf(context).bottom > 0;
          final field = TextField(
            controller: _text, enabled: widget.enabled && !_sending,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLength: 500, maxLines: 1, textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              hintText: ar ? 'تعليق…' : 'Message…', counterText: '',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true, fillColor: const Color(0xFF123C30),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
              suffixIcon: typing ? IconButton(
                tooltip: ar ? 'إرسال' : 'Send', onPressed: _sending ? null : _send,
                icon: const Icon(Icons.send_rounded, color: Color(0xFFE7C56E), size: 20)) : null,
            ),
          );
          final actions = [
            _action(Icons.card_giftcard_rounded, ar ? 'الهدايا' : 'Gifts', widget.onGifts, color: const Color(0xFFFFC577)),
            _action(Icons.palette_outlined, ar ? 'المظهر' : 'Appearance', widget.onShop),
            _action(Icons.grid_view_rounded, ar ? 'الأدوات' : 'Tools', widget.onTools),
            _action(Icons.closed_caption_outlined, ar ? 'مساعدة اللغة' : 'Language assistance', widget.onCaptions),
            if (widget.showMic) _action(widget.micIcon, widget.micLabel, widget.onMic),
          ];
          final narrow = constraints.maxWidth < 350 ||
              MediaQuery.textScalerOf(context).scale(14) > 20;
          // Keep the same keyed input mounted when the keyboard hides actions.
          // Replacing a Row with a bare TextField would lose input focus.
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              if (!typing && !narrow) ...[
                ...actions, const SizedBox(width: 6),
              ],
              Expanded(key: const ValueKey('room-message-input'), child: field),
            ]),
            if (!typing && narrow) ...[
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: actions),
            ],
          ]);
        }),
      ),
    ]);
  }
}
