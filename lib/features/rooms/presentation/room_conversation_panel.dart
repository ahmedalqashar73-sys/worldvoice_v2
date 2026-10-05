import 'package:flutter/material.dart';
import '../data/room_chat_message.dart';
import '../data/room_feature_models.dart';

/// Live room conversation, independent of Firebase for layout testing.
class RoomConversationPanel extends StatefulWidget {
  const RoomConversationPanel({
    required this.messages, required this.onSend, required this.isArabic,
    required this.onGifts, required this.onShop, required this.onTools,
    required this.onCaptions, required this.onMic, required this.micIcon,
    required this.micLabel, this.onTranslateMessage,
    this.translationHint, this.enabled = true, super.key,
  });
  final Stream<List<RoomChatMessage>> messages;
  final Future<void> Function(String) onSend;
  final bool isArabic;
  final bool enabled;
  final VoidCallback onGifts, onShop, onTools, onCaptions;
  final VoidCallback? onMic;
  final IconData micIcon;
  final String micLabel;
  final Future<String> Function(String text)? onTranslateMessage;
  final String? translationHint;
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
  final Map<String, String> _translations = <String, String>{};
  final Set<String> _translating = <String>{};

  Future<void> _translate(RoomChatMessage message) async {
    final translate = widget.onTranslateMessage;
    if (translate == null ||
        _translations.containsKey(message.id) ||
        _translating.contains(message.id)) {
      return;
    }
    setState(() => _translating.add(message.id));
    try {
      final translated = await translate(message.text);
      if (!mounted) return;
      setState(() => _translations[message.id] = translated.trim());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isArabic
                ? 'تعذرت الترجمة الآن. حاول مرة أخرى.'
                : 'Translation is unavailable right now. Please retry.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _translating.remove(message.id));
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }
  Future<void> _openComposer() async {
    if (!widget.enabled || !mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF0E241E),
      builder: (sheetContext) {
        final inset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, inset + 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  autofocus: true,
                  enabled: !_sending,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 500,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) async {
                    await _send();
                    if (sheetContext.mounted && _text.text.trim().isEmpty) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: widget.isArabic ? 'اكتب رسالة…' : 'Write a message…',
                    counterText: '',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF123C30),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: widget.isArabic ? 'إرسال' : 'Send',
                onPressed: _sending
                    ? null
                    : () async {
                        await _send();
                        if (sheetContext.mounted && _text.text.trim().isEmpty) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                icon: const Icon(
                  Icons.send_rounded,
                  color: Color(0xFFE7C56E),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
    // Keep the chat viewport independent of the keyboard. Only the
    // composer floats above it while the room stage remains completely fixed.
    // The real editor lives in a modal sheet, so the room stage and collapsed
    // chat controls never react to the keyboard inset.
    const keyboardInset = 0.0;
    return Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(child: StreamBuilder<List<RoomChatMessage>>(
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
            reverse: true, padding: EdgeInsets.fromLTRB(16, 12, 16,
              keyboardInset > 0 ? keyboardInset + 70 : 92),
            itemCount: messages.length + 1,
            itemBuilder: (context, index) {
              final welcome = index == messages.length;
              final msg = welcome ? null : messages[index];
              final giftPreview = msg == null
                  ? null
                  : RoomGiftPreviewChatCodec.decode(msg.text);
              final translated = msg == null ? null : _translations[msg.id];
              final translating =
                  msg != null && _translating.contains(msg.id);
              final bubble = Align(
                alignment: AlignmentDirectional.centerStart,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: msg == null || giftPreview != null ||
                          widget.onTranslateMessage == null
                      ? null
                      : () => _translate(msg),
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF102C25).withValues(alpha: .8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: welcome
                                    ? 'WorldVoice  '
                                    : '${msg!.displayName}  ',
                                style: const TextStyle(
                                  color: Color(0xFFE7C56E),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: welcome
                                    ? (ar
                                        ? 'أهلًا بك! تعلّم وتحدث وشارك باحترام.'
                                        : 'Welcome! Learn, talk and share with respect.')
                                    : giftPreview != null
                                        ? (ar
                                            ? '🎁 معاينة هدية مجانية لصديق • دون خصم كوينات'
                                            : '🎁 Free gift effect for a friend • no coins')
                                        : msg!.text,
                              ),
                            ],
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        if (translated?.isNotEmpty == true) ...[
                          const SizedBox(height: 6),
                          const Divider(
                            height: 1,
                            color: Colors.white12,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            translated!,
                            style: const TextStyle(
                              color: Color(0xFF8EEAD0),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ] else if (translating) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox.square(
                                dimension: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.6,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                ar ? 'جارٍ الترجمة…' : 'Translating…',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ] else if (msg != null &&
                            giftPreview == null &&
                            widget.onTranslateMessage != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.translationHint ??
                                (ar
                                    ? 'اضغط لترجمة الرسالة لك فقط'
                                    : 'Tap to translate for you only'),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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
      Positioned(
        left: 0, right: 0, bottom: keyboardInset,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: LayoutBuilder(builder: (context, constraints) {
          final field = TextField(
            key: const ValueKey<String>('worldvoice-room-chat-input'),
            controller: _text,
            enabled: widget.enabled,
            readOnly: true,
            showCursor: false,
            onTap: _openComposer,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 1,
            decoration: InputDecoration(
              hintText: ar ? 'تعليق…' : 'Message…',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF123C30),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
            ),
          );
          final actions = [
            _action(Icons.card_giftcard_rounded, ar ? 'الهدايا' : 'Gifts', widget.onGifts, color: const Color(0xFFFFC577)),
            _action(Icons.storefront_rounded, ar ? 'المتجر' : 'Shop', widget.onShop),
            _action(Icons.grid_view_rounded, ar ? 'الأدوات' : 'Tools', widget.onTools),
            _action(Icons.closed_caption_outlined, ar ? 'الترجمة' : 'Captions', widget.onCaptions),
            if (widget.onMic != null)
              _action(widget.micIcon, widget.micLabel, widget.onMic),
          ];
          if (constraints.maxWidth < 350 ||
              MediaQuery.textScalerOf(context).scale(14) > 20) {
            return Column(mainAxisSize: MainAxisSize.min, children: [
              field, const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: actions),
            ]);
          }
          return Row(children: [...actions, const SizedBox(width: 6), Expanded(child: field)]);
        }),
      )),
    ]);
  }
}
