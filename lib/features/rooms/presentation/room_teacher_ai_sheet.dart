import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../services/room_teacher_ai_service.dart';

class RoomTeacherAiSheet extends StatefulWidget {
  const RoomTeacherAiSheet({
    required this.service,
    required this.roomLanguageCode,
    super.key,
  });

  final RoomTeacherAiService service;
  final String roomLanguageCode;

  @override
  State<RoomTeacherAiSheet> createState() => _RoomTeacherAiSheetState();
}

class _RoomTeacherAiSheetState extends State<RoomTeacherAiSheet> {
  final TextEditingController _questionController = TextEditingController();
  final List<_TeacherMessage> _messages = <_TeacherMessage>[];
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speech = SpeechToText();
  bool _sending = false;
  bool _voiceEnabled = true;
  bool _listening = false;
  String? _error;

  String get _roomLocale {
    final code = widget.roomLanguageCode.toLowerCase().split(RegExp('[-_]')).first;
    return switch (code) {
      'ar' => 'ar-SA',
      'en' => 'en-US',
      'es' => 'es-ES',
      'fr' => 'fr-FR',
      'de' => 'de-DE',
      'pt' => 'pt-PT',
      'tr' => 'tr-TR',
      'ru' => 'ru-RU',
      'zh' => 'zh-CN',
      'ja' => 'ja-JP',
      'ko' => 'ko-KR',
      'ur' => 'ur-PK',
      'fa' => 'fa-IR',
      'id' => 'id-ID',
      'th' => 'th-TH',
      _ => widget.roomLanguageCode,
    };
  }

  @override
  void dispose() {
    unawaited(_tts.stop());
    unawaited(_speech.cancel());
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _speak(String answer) async {
    if (!_voiceEnabled || answer.isEmpty) return;
    try {
      await _tts.stop();
      await _tts.setLanguage(_roomLocale);
      await _tts.setSpeechRate(0.48);
      await _tts.speak(answer);
    } catch (error) {
      if (mounted) setState(() => _error = 'Voice playback failed: $error');
    }
  }

  Future<void> _toggleMicrophone() async {
    if (_sending) return;
    if (_speech.isListening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    try {
      final available = await _speech.initialize(
        onError: (error) {
          if (mounted) {
            setState(() {
              _listening = false;
              _error = error.errorMsg;
            });
          }
        },
        onStatus: (status) {
          if (mounted) {
            setState(
              () => _listening = status == SpeechToText.listeningStatus,
            );
          }
        },
      );
      if (!available) {
        if (mounted) {
          setState(() => _error = 'Speech recognition is unavailable.');
        }
        return;
      }
      final language = widget.roomLanguageCode.toLowerCase().split(RegExp('[-_]')).first;
      final locales = await _speech.locales();
      String? localeId;
      for (final locale in locales) {
        if (locale.localeId.toLowerCase().split(RegExp('[-_]')).first == language) {
          localeId = locale.localeId;
          break;
        }
      }
      await _speech.listen(
        localeId: localeId,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
        ),
        onResult: (result) {
          if (!mounted) return;
          final words = result.recognizedWords.trim();
          if (words.isEmpty) return;
          _questionController.value = TextEditingValue(
            text: words,
            selection: TextSelection.collapsed(offset: words.length),
          );
        },
      );
      if (mounted) {
        setState(() {
          _listening = _speech.isListening;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _listening = false;
          _error = 'Microphone failed: $error';
        });
      }
    }
  }

  Future<void> _send() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _sending) return;
    if (_speech.isListening) await _speech.stop();
    if (!mounted) return;

    setState(() {
      _messages.add(_TeacherMessage(text: question, fromUser: true));
      _questionController.clear();
      _sending = true;
      _error = null;
    });

    try {
      final answer = await widget.service.ask(
        prompt: question,
        roomLanguageCode: widget.roomLanguageCode,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(_TeacherMessage(text: answer, fromUser: false));
      });
      unawaited(_speak(answer));
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: _voiceEnabled ? 'Mute AI voice' : 'Enable AI voice',
                      onPressed: () {
                        setState(() => _voiceEnabled = !_voiceEnabled);
                        if (!_voiceEnabled) unawaited(_tts.stop());
                      },
                      icon: Icon(_voiceEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded),
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
                  IconButton(
                    tooltip: _listening ? 'Stop voice input' : 'Ask by voice',
                    onPressed: _sending ? null : _toggleMicrophone,
                    icon: Icon(
                      _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _listening ? Colors.redAccent : null,
                    ),
                  ),
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
