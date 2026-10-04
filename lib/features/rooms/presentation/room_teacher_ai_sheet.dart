import 'package:flutter/material.dart';

import '../services/room_teacher_ai_service.dart';

class RoomTeacherAiSheet extends StatefulWidget {
  const RoomTeacherAiSheet({
    required this.service,
    required this.roomLanguageCode,
    this.onAnswer,
    this.onVoicePressed,
    this.canSpeak = false,
    this.listening = false,
    this.closeAfterAnswer = false,
    super.key,
  });

  final RoomTeacherAiService service;
  final String roomLanguageCode;
  final ValueChanged<String>? onAnswer;
  final VoidCallback? onVoicePressed;
  final bool canSpeak;
  final bool listening;
  final bool closeAfterAnswer;

  @override
  State<RoomTeacherAiSheet> createState() => _RoomTeacherAiSheetState();
}

class _RoomTeacherAiSheetState extends State<RoomTeacherAiSheet> {
  final TextEditingController _questionController = TextEditingController();
  final List<_TeacherMessage> _messages = <_TeacherMessage>[];
  bool _sending = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _sending) return;

    setState(() {
      _messages.add(_TeacherMessage(text: question, fromUser: true));
      _questionController.clear();
      _sending = true;
      _error = null;
      _notice = null;
    });

    try {
      final answer = await widget.service.ask(
        prompt: question,
        roomLanguageCode: widget.roomLanguageCode,
      );
      if (!mounted) return;
      if (answer.trim().isEmpty) {
        final isArabic =
            Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
        setState(() {
          _notice = isArabic
              ? 'Teacher AI يستجيب فقط بلغة الروم.'
              : 'Teacher AI responds only in the room language.';
        });
        return;
      }
      setState(() {
        _messages.add(_TeacherMessage(text: answer, fromUser: false));
      });
      widget.onAnswer?.call(answer);
      if (widget.closeAfterAnswer && mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 6, 14, 14 + bottomInset),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF3A2D71),
                  child: Icon(Icons.smart_toy_rounded, color: Colors.white),
                ),
                title: const Text(
                  'Teacher AI',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  isArabic
                      ? 'اسأل عن اللغة أو القواعد أو التصحيح داخل الروم.'
                      : 'Ask about language, grammar, or corrections in the room.',
                ),
                trailing: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                child: Material(
                  color: widget.listening
                      ? const Color(0xFF0E6F52)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: widget.canSpeak ? widget.onVoicePressed : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: widget.listening
                                ? const Color(0xFF32D294)
                                : Theme.of(context).colorScheme.primary,
                            child: Icon(
                              widget.listening
                                  ? Icons.graphic_eq_rounded
                                  : Icons.mic_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.canSpeak
                                      ? (widget.listening
                                          ? (isArabic
                                              ? 'تكلم الآن — Teacher AI يسمعك'
                                              : 'Speak now — Teacher AI is listening')
                                          : (isArabic
                                              ? 'اضغط وتكلم مع Teacher AI'
                                              : 'Tap and speak with Teacher AI'))
                                      : (isArabic
                                          ? 'اصعد إلى مقعد متحدث لتتكلم مع Teacher AI'
                                          : 'Join a speaker seat to talk with Teacher AI'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: widget.listening
                                        ? Colors.white
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isArabic
                                      ? 'الكلام يتحول إلى نص داخليًا، ثم يرد Teacher AI عليك بصوت داخل الغرفة.'
                                      : 'Your speech is transcribed locally, then Teacher AI answers aloud in the room.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.listening
                                        ? Colors.white70
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
                  ),
                ),
              ),
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Text(
                            isArabic
                                ? 'اكتب سؤالك لـ Teacher AI.\nمثال: صحح هذه الجملة أو اشرح لي هذه القاعدة.'
                                : 'Ask Teacher AI a question.\nFor example: correct this sentence or explain this grammar rule.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return Align(
                            alignment: message.fromUser
                                ? AlignmentDirectional.centerEnd
                                : AlignmentDirectional.centerStart,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 340),
                              margin: const EdgeInsets.only(bottom: 9),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: message.fromUser
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: SelectableText(message.text),
                            ),
                          );
                        },
                      ),
              ),
              if (_notice?.trim().isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _notice!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (_error?.trim().isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  isArabic ? 'اكتب بدلًا من الكلام' : 'Type instead',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _questionController,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 1200,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: isArabic
                                ? 'اسأل Teacher AI...'
                                : 'Ask Teacher AI...',
                            counterText: '',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sending ? null : _send,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherMessage {
  const _TeacherMessage({
    required this.text,
    required this.fromUser,
  });

  final String text;
  final bool fromUser;
}