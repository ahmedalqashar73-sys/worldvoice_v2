import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/room_teacher_ai_service.dart';

class RoomTeacherAiSheet extends StatelessWidget {
  const RoomTeacherAiSheet({
    required this.service,
    required this.roomLanguageCode,
    this.onVoicePressed,
    this.canSpeak = false,
    this.listening = false,
    this.online,
    this.onlineListenable,
    this.closeAfterAnswer = false,
    super.key,
  });

  final RoomTeacherAiService service;
  final String roomLanguageCode;
  final VoidCallback? onVoicePressed;
  final bool canSpeak;
  final bool listening;
  final bool? online;
  final ValueListenable<bool>? onlineListenable;

  // Retained for source compatibility with the Live surface. The room
  // experience is voice-only and closes explicitly with the close button.
  final bool closeAfterAnswer;

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    Widget content(bool isOnline) {
      final active = isOnline && canSpeak && listening;
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .62,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Teacher AI',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOnline
                                    ? const Color(0xFF32D294)
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              isOnline
                                  ? (isArabic ? 'متصل' : 'Online')
                                  : (isArabic ? 'غير متصل' : 'Offline'),
                              style: TextStyle(
                                color: isOnline
                                    ? const Color(0xFF32D294)
                                    : Colors.grey,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFF3A2D71),
                      child: Icon(
                        Icons.smart_toy_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                const Spacer(),
                GestureDetector(
                  onTap: canSpeak && isOnline ? onVoicePressed : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: active ? 142 : 126,
                    height: active ? 142 : 126,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? const Color(0xFF0E9C70)
                          : const Color(0xFF145D49),
                      border: Border.all(
                        color: active
                            ? const Color(0xFF7FF4C7)
                            : Colors.white24,
                        width: 3,
                      ),
                      boxShadow: active
                          ? const [
                              BoxShadow(
                                color: Color(0x6632D294),
                                blurRadius: 30,
                                spreadRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      active
                          ? Icons.graphic_eq_rounded
                          : Icons.mic_rounded,
                      color: Colors.white,
                      size: 58,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  !isOnline
                      ? (isArabic
                          ? 'Teacher AI غير متصل بخدمة الذكاء الآن.'
                          : 'Teacher AI is offline right now.')
                      : !canSpeak
                          ? (isArabic
                              ? 'اصعد إلى أحد مقاعد المتحدثين حتى تتكلم مع Teacher AI.'
                              : 'Join a speaker seat to talk with Teacher AI.')
                          : active
                              ? (isArabic
                                  ? 'تكلم طبيعيًا الآن — Teacher AI يسمعك ويرد عليك بصوت.'
                                  : 'Speak naturally now — Teacher AI is listening and will answer aloud.')
                              : (isArabic
                                  ? 'Teacher AI جاهز. ابدأ الكلام.'
                                  : 'Teacher AI is ready. Start speaking.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    height: 1.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isOnline
                      ? (isArabic
                          ? 'ناقش أي موضوع، اسأل، جاوب، وتدرّب على اللغة. لا تحتاج للكتابة.'
                          : 'Discuss any topic, ask questions, answer, and practice. No typing required.')
                      : (isArabic
                          ? 'الروم والصوت يعملان، لكن خدمة AI الخارجية غير متاحة حاليًا.'
                          : 'The room and audio still work, but the external AI service is unavailable.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Chip(
                  avatar: const Icon(Icons.language_rounded, size: 17),
                  label: Text(
                    isArabic
                        ? 'لغة الغرفة: ${roomLanguageCode.toUpperCase()}'
                        : 'Room language: ${roomLanguageCode.toUpperCase()}',
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    final listenable = onlineListenable;
    if (listenable != null) {
      return ValueListenableBuilder<bool>(
        valueListenable: listenable,
        builder: (context, value, _) => content(value),
      );
    }
    return content(online ?? service.isAskConfigured);
  }
}
