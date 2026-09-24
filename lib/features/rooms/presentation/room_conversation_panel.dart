import 'package:flutter/material.dart';
import '../data/room_chat_message.dart';

/// Live room conversation, independent of Firebase for layout testing.
class RoomConversationPanel extends StatefulWidget {
  const RoomConversationPanel({
    required this.messages, required this.onSend, required this.isArabic,
    required this.onGifts, required this.onShop, required this.onTools,
    required this.onCaptions, required this.onMic, required this.micIcon,
    required this.micLabel, this.enabled = true, super.key,
  });
  final Stream<List<RoomChatMessage>> messages;
  final Future<void> Function(String) onSend;
  final bool isArabic;
  final bool enabled;
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
          return ListView.builder(
            reverse: true, padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: messages.length + 1,
            itemBuilder: (context, index) {
              final welcome = index == messages.length;
              final msg = welcome ? null : messages[index];
              return Align(
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
            },
          );
        },
      )),
      Padding(
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
            _action(Icons.storefront_rounded, ar ? 'المتجر' : 'Shop', widget.onShop),
            _action(Icons.grid_view_rounded, ar ? 'الأدوات' : 'Tools', widget.onTools),
            _action(Icons.closed_caption_outlined, ar ? 'الترجمة' : 'Captions', widget.onCaptions),
            _action(widget.micIcon, widget.micLabel, widget.onMic),
          ];
          if (typing) return field;
          if (constraints.maxWidth < 350 || MediaQuery.textScalerOf(context).scale(14) > 20) {
            return Column(mainAxisSize: MainAxisSize.min, children: [
              field, const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: actions),
            ]);
          }
          return Row(children: [...actions, const SizedBox(width: 6), Expanded(child: field)]);
        }),
      ),
    ]);
  }
}
