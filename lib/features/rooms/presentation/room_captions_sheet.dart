import 'package:flutter/material.dart';

import '../data/room_caption.dart';
import '../data/room_teacher_ai_note.dart';

class RoomCaptionsSheet extends StatelessWidget {
  const RoomCaptionsSheet({
    required this.enabled,
    required this.translationEnabled,
    required this.pronunciationEnabled,
    required this.targetLanguage,
    required this.canPublish,
    required this.listening,
    required this.onEnabledChanged,
    required this.onTranslationChanged,
    required this.onPronunciationChanged,
    required this.onTargetLanguageChanged,
    this.pronunciationNotes,
    this.targetLanguages,
    this.error,
    super.key,
  });

  final bool enabled;
  final bool translationEnabled;
  final bool pronunciationEnabled;
  final String targetLanguage;
  final Stream<List<RoomTeacherAiNote>>? pronunciationNotes;
  final List<RoomCaptionLanguage>? targetLanguages;
  final bool canPublish;
  final bool listening;
  final String? error;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<bool> onTranslationChanged;
  final ValueChanged<bool> onPronunciationChanged;
  final ValueChanged<String> onTargetLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    final availableLanguages =
        targetLanguages == null || targetLanguages!.isEmpty
            ? roomCaptionLanguages
            : targetLanguages!;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.closed_caption_rounded),
              title: Text(
                isArabic ? 'أدوات اللغة' : 'Language tools',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                isArabic
                    ? 'كل خيار هنا خاص بك فقط ولا يغيّر شاشة بقية الموجودين في الغرفة.'
                    : 'Each option here is private to your screen and does not change what others see.',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: enabled,
              onChanged: onEnabledChanged,
              secondary: Icon(
                listening
                    ? Icons.graphic_eq_rounded
                    : Icons.subtitles_rounded,
              ),
              title: Text(
                isArabic ? 'السبتايتل المباشر' : 'Live subtitles',
              ),
              subtitle: canPublish
                  ? Text(
                      listening
                          ? (isArabic
                              ? 'يتم تجهيز نص كلامك للذين فعّلوا السبتايتل على أجهزتهم.'
                              : 'Your speech is being prepared for members who enabled subtitles on their own devices.')
                          : (isArabic
                              ? 'النص يظهر عندك فقط إذا فعّلت السبتايتل، ولا يُفرض على الآخرين.'
                              : 'Subtitles appear only on your screen when you enable them; they are not forced on others.'),
                    )
                  : Text(
                      isArabic
                          ? 'ستشاهد عندك فقط نص المتحدثين الموجودين على الستيج.'
                          : 'Only you will see captions from speakers on stage.',
                    ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: translationEnabled,
              onChanged: onTranslationChanged,
              secondary: const Icon(Icons.translate_rounded),
              title: Text(
                isArabic ? 'الترجمة الفورية' : 'Instant translation',
              ),
              subtitle: Text(
                isArabic
                    ? 'الترجمة تظهر لك أنت فقط، واللغة الافتراضية هي لغتك الأم من البروفايل.'
                    : 'Translation is shown only to you; your profile native language is the default target.',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: pronunciationEnabled,
              onChanged: onPronunciationChanged,
              secondary: const Icon(Icons.record_voice_over_rounded),
              title: Text(isArabic ? 'تصحيح النطق' : 'Pronunciation guidance'),
              subtitle: Text(isArabic
                  ? 'يعتمد على الكلام المحوّل إلى نص بواسطة Teacher AI، ولا يقيم الصوت نفسه. يحتاج خادم AI.'
                  : 'Teacher AI gives guidance from captions, not an audio pronunciation score. An AI server is required.'),
            ),
            if (pronunciationEnabled && pronunciationNotes != null)
              SizedBox(
                height: 155,
                child: StreamBuilder<List<RoomTeacherAiNote>>(
                  stream: pronunciationNotes,
                  builder: (context, notesSnapshot) {
                    if (notesSnapshot.hasError) {
                      return Center(child: Text(isArabic
                          ? 'تعذّر تحميل ملاحظات النطق.'
                          : 'Could not load pronunciation guidance.'));
                    }
                    final notes = notesSnapshot.data ??
                        const <RoomTeacherAiNote>[];
                    if (notes.isEmpty) {
                      return Center(child: Text(isArabic
                          ? 'تكلّم لتظهر ملاحظات النص والنطق إذا كان خادم AI متاحًا.'
                          : 'Speak to see transcript-based guidance when AI is available.'));
                    }
                    return ListView(
                      children: [
                        for (final note in notes.take(4))
                          Card(
                            child: ListTile(
                              title: Text(note.correction.isEmpty
                                  ? note.originalText : note.correction),
                              subtitle: Text(
                                note.pronunciationTip?.trim().isNotEmpty == true
                                    ? note.pronunciationTip!
                                    : (isArabic
                                        ? 'لا توجد ملاحظة نطق لهذه الجملة.'
                                        : 'No pronunciation note for this sentence.'),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            if (translationEnabled)
              if (availableLanguages.length == 1)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.school_rounded),
                  title: Text(
                    isArabic ? 'لغة الترجمة (لغتك الأم)' : 'Translation language (native)',
                  ),
                  subtitle: Text(availableLanguages.first.label),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: availableLanguages.any(
                    (item) => item.code == targetLanguage,
                  )
                      ? targetLanguage
                      : availableLanguages.first.code,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText:
                        isArabic ? 'لغة الترجمة (لغتك الأم)' : 'Translation language (native)',
                  ),
                  items: [
                    for (final item in availableLanguages)
                      DropdownMenuItem(
                        value: item.code,
                        child: Text(
                          item.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) onTargetLanguageChanged(value);
                  },
                ),
            if (error?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color:
                            Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error!,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RoomCaptionOverlay extends StatelessWidget {
  const RoomCaptionOverlay({
    required this.caption,
    required this.translationEnabled,
    this.showOriginal = true,
    this.translatedText,
    super.key,
  });

  final RoomCaption caption;
  final bool translationEnabled;
  final bool showOriginal;
  final String? translatedText;

  @override
  Widget build(BuildContext context) {
    final translated = translatedText?.trim() ?? '';
    final showTranslated =
        translationEnabled && translated.isNotEmpty && translated != caption.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.closed_caption_rounded,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  caption.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                caption.languageCode.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          if (showOriginal)
            Text(
              caption.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          if (showTranslated) ...[
            const SizedBox(height: 6),
            Text(
              translated,
              style: const TextStyle(
                color: Color(0xFF8EEAD0),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class RoomCaptionLanguage {
  const RoomCaptionLanguage(this.code, this.label);

  final String code;
  final String label;
}

const List<RoomCaptionLanguage> roomCaptionLanguages = [
  RoomCaptionLanguage('ar', 'العربية'),
  RoomCaptionLanguage('en', 'English'),
  RoomCaptionLanguage('es', 'Español'),
  RoomCaptionLanguage('fr', 'Français'),
  RoomCaptionLanguage('de', 'Deutsch'),
  RoomCaptionLanguage('pt', 'Português'),
  RoomCaptionLanguage('tr', 'Türkçe'),
  RoomCaptionLanguage('ru', 'Русский'),
  RoomCaptionLanguage('zh', '中文'),
  RoomCaptionLanguage('ja', '日本語'),
  RoomCaptionLanguage('ko', '한국어'),
  RoomCaptionLanguage('ur', 'اردو'),
  RoomCaptionLanguage('fa', 'فارسی'),
  RoomCaptionLanguage('id', 'Indonesia'),
  RoomCaptionLanguage('th', 'ไทย'),
  RoomCaptionLanguage('hi', 'हिन्दी'),
];
