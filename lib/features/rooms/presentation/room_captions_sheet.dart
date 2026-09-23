import 'package:flutter/material.dart';

import '../data/room_caption.dart';

class RoomCaptionsSheet extends StatelessWidget {
  const RoomCaptionsSheet({
    required this.enabled,
    required this.translationEnabled,
    required this.targetLanguage,
    required this.canPublish,
    required this.listening,
    required this.onEnabledChanged,
    required this.onTranslationChanged,
    required this.onTargetLanguageChanged,
    this.error,
    super.key,
  });

  final bool enabled;
  final bool translationEnabled;
  final String targetLanguage;
  final bool canPublish;
  final bool listening;
  final String? error;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<bool> onTranslationChanged;
  final ValueChanged<String> onTargetLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.closed_caption_rounded),
              title: Text(
                isArabic ? 'الترجمة المباشرة' : 'Live captions',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                isArabic
                    ? 'مجانية لكل المستخدمين. المتحدث ينشر النص من جهازه.'
                    : 'Free for everyone. Speakers publish captions from their device.',
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
                isArabic ? 'تشغيل Live Captions' : 'Enable live captions',
              ),
              subtitle: canPublish
                  ? Text(
                      listening
                          ? (isArabic
                              ? 'يتم تحويل كلامك إلى نص الآن.'
                              : 'Your speech is being captioned now.')
                          : (isArabic
                              ? 'سيبدأ التعرف عندما يكون المايك متاحًا.'
                              : 'Recognition starts when your microphone is available.'),
                    )
                  : Text(
                      isArabic
                          ? 'ستشاهد نص المتحدثين الموجودين على الستيج.'
                          : 'You will see captions from speakers on stage.',
                    ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: translationEnabled,
              onChanged: enabled ? onTranslationChanged : null,
              secondary: const Icon(Icons.translate_rounded),
              title: Text(
                isArabic ? 'ترجمة النص' : 'Translate captions',
              ),
              subtitle: Text(
                isArabic
                    ? 'الترجمة تتم على الجهاز بعد تنزيل نموذج اللغة.'
                    : 'Translation runs on-device after its language model downloads.',
              ),
            ),
            if (enabled && translationEnabled)
              DropdownButtonFormField<String>(
                initialValue: targetLanguage,
                decoration: InputDecoration(
                  labelText:
                      isArabic ? 'لغة الترجمة' : 'Translation language',
                ),
                items: [
                  for (final item in roomCaptionLanguages)
                    DropdownMenuItem(
                      value: item.code,
                      child: Text(item.label),
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
    this.translatedText,
    super.key,
  });

  final RoomCaption caption;
  final bool translationEnabled;
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
