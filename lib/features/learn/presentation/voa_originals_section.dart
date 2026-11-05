import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

/// A curated, attributed set of REAL VOA English voice recordings.
/// The full, exact transcript lives on the matching original VOA page.
/// No WorldVoice script is ever passed off as the original spoken words.
class VoaOriginalLesson {
  const VoaOriginalLesson({
    required this.id,
    required this.number,
    required this.title,
    required this.titleAr,
    required this.audioUrl,
    required this.sourceUrl,
    required this.durationSec,
    required this.petePresent,
    this.existingEpisodeId,
  });

  final String id;
  final int number;
  final String title;
  final String titleAr;
  final String audioUrl;
  final String sourceUrl;
  final int durationSec;
  final bool petePresent;
  final String? existingEpisodeId;

  factory VoaOriginalLesson.fromJson(Map<String, dynamic> json) =>
      VoaOriginalLesson(
        id: json['id'] as String,
        number: json['voa_lesson_number'] as int,
        title: json['title'] as String,
        titleAr: json['title_ar'] as String,
        audioUrl: json['audio_url'] as String,
        sourceUrl: json['source_url'] as String,
        durationSec: json['duration_sec'] as int,
        petePresent: json['pete_present'] as bool? ?? false,
        existingEpisodeId: json['existing_episode_id'] as String?,
      );

  bool get isOfficialSource {
    final audio = Uri.tryParse(audioUrl);
    final transcript = Uri.tryParse(sourceUrl);
    return audio != null && transcript != null &&
        audio.scheme == 'https' &&
        audio.host == 'voa-audio.voanews.eu' &&
        audio.path.startsWith('/vle/') &&
        audio.path.endsWith('.mp3') &&
        transcript.scheme == 'https' &&
        transcript.host == 'learningenglish.voanews.com' &&
        durationSec > 0;
  }
}

class VoaOriginalCatalog {
  const VoaOriginalCatalog();

  Future<List<VoaOriginalLesson>> load() async {
    const asset = 'assets/podcasts/voa_english_a1_originals.json';
    final raw = await rootBundle.loadString(asset);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final items = (map['lessons'] as List<dynamic>)
        .map((item) => VoaOriginalLesson.fromJson(
            item as Map<String, dynamic>))
        .toList(growable: false);
    if (items.length != 15 ||
        items.map((e) => e.id).toSet().length != 15 ||
        items.any((item) => !item.isOfficialSource)) {
      throw const FormatException('VOA original audio catalog invalid');
    }
    return items;
  }
}

/// The main English A1 audio list is all one PROVIDER (VOA).
/// Anna is the returning voice; the VOA cast includes other speakers.
class VoaOriginalsSection extends StatefulWidget {
  const VoaOriginalsSection({super.key, required this.onOpen});
  final ValueChanged<VoaOriginalLesson> onOpen;

  @override
  State<VoaOriginalsSection> createState() => _VoaOriginalsSectionState();
}

class _VoaOriginalsSectionState extends State<VoaOriginalsSection> {
  late final Future<List<VoaOriginalLesson>> _lessons =
      const VoaOriginalCatalog().load();

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(ar ? 'تسجيلات VOA الأصلية — 15 حلقة'
          : 'VOA original audio — 15 episodes',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5),
      Text(ar
          ? 'جميع التسجيلات من VOA. آنا صوت رئيسي متكرر، ويشارك بيت وشخصيات أخرى حسب الحلقة. لا توجد أصوات آلية في هذه القائمة.'
          : 'Every recording is from VOA. Anna is a recurring voice; Pete and other characters appear when they are part of the original lesson. No synthetic voices here.',
          style: TextStyle(fontSize: 12, height: 1.5,
              color: scheme.onSurfaceVariant)),
      const SizedBox(height: 10),
      FutureBuilder<List<VoaOriginalLesson>>(
        future: _lessons,
        builder: (context, state) {
          if (state.hasError) {
            return Text(ar ? 'تعذر قراءة فهرس VOA.' : 'VOA index unavailable.');
          }
          if (!state.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(children: [
            for (final lesson in state.data!)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                color: scheme.surfaceContainerLow,
                child: ListTile(
                  key: ValueKey('podcast-original-${lesson.id}'),
                  onTap: () => widget.onOpen(lesson),
                  leading: Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCF0E3),
                      borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.headphones_rounded,
                        color: Color(0xFF19694D)),
                  ),
                  title: Text(ar ? lesson.titleAr : lesson.title,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                    lesson.number == 20
                      ? (ar ? 'VOA · صوت أصلي · تزامن تجريبي'
                          : 'VOA human audio · provisional sync')
                      : (ar
                          ? 'Anna${lesson.petePresent ? ' + Pete' : ' + ضيوف'} · تسجيل VOA بشري أصلي'
                          : 'Anna${lesson.petePresent ? ' + Pete' : ' + guests'} · original human VOA audio'),
                    style: TextStyle(fontSize: 11,
                        color: scheme.onSurfaceVariant),
                  ),
                  trailing: const Icon(Icons.play_circle_fill_rounded,
                      color: Color(0xFF23875F)),
                ),
              ),
          ]);
        },
      ),
    ]);
  }
}

/// Used only for VOA lessons whose exact line timings have NOT been checked.
/// Audio remains inside WorldVoice; the matching full transcript is provided
/// at its official VOA source instead of displaying fabricated captions.
class VoaOriginalAudioScreen extends StatefulWidget {
  const VoaOriginalAudioScreen({super.key, required this.lesson});
  final VoaOriginalLesson lesson;

  @override
  State<VoaOriginalAudioScreen> createState() => _VoaOriginalAudioScreenState();
}

class _VoaOriginalAudioScreenState extends State<VoaOriginalAudioScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (!widget.lesson.isOfficialSource) {
        throw const FormatException('Unverified VOA audio source');
      }
      await _player.setUrl(widget.lesson.audioUrl)
          .timeout(const Duration(seconds: 25));
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Audio could not be loaded from VOA.');
      }
    }
  }

  Future<void> _openOfficialTranscript() async {
    final uri = Uri.parse(widget.lesson.sourceUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _clock(Duration value) {
    final seconds = value.inSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final lesson = widget.lesson;
    return Scaffold(
      appBar: AppBar(title: Text(ar ? lesson.titleAr : lesson.title)),
      body: ListView(padding: const EdgeInsets.all(17), children: [
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF113C2F), Color(0xFF1E7658)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Row(children: [
              Icon(Icons.headphones_rounded, color: Color(0xFFF1D98F)),
              SizedBox(width: 7),
              Expanded(child: Text('VOA LEARNING ENGLISH · ORIGINAL AUDIO',
                  style: TextStyle(color: Color(0xFFF1D98F),
                      fontSize: 11, fontWeight: FontWeight.w900))),
            ]),
            const SizedBox(height: 14),
            Text(lesson.title,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text(lesson.petePresent ? 'Anna · Pete · VOA cast'
                : 'Anna · VOA cast',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            if (_error != null)
              Text(ar ? 'تعذّر تحميل صوت VOA. يمكنك فتح المصدر الأصلي.'
                  : _error!, style: const TextStyle(color: Colors.white)),
            if (_ready)
              StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final total = _player.duration ??
                      Duration(seconds: lesson.durationSec);
                  final end = total.inMilliseconds > 0
                      ? total.inMilliseconds : 1;
                  return Column(children: [
                    Row(children: [
                      StreamBuilder<PlayerState>(
                        stream: _player.playerStateStream,
                        builder: (context, state) {
                          final playing = state.data?.playing ?? false;
                          return IconButton.filled(
                            key: const ValueKey('voa-original-play'),
                            onPressed: () {
                              if (playing) {
                                _player.pause();
                              } else if (_player.processingState ==
                                  ProcessingState.completed) {
                                _player.seek(Duration.zero).then((_) =>
                                    _player.play());
                              } else {
                                _player.play();
                              }
                            },
                            icon: Icon(playing
                                ? Icons.pause_rounded : Icons.play_arrow_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFF1D98F),
                              foregroundColor: const Color(0xFF153F31)),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      Text('${_clock(position)} / ${_clock(total)}',
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    ]),
                    Slider(
                      value: position.inMilliseconds.clamp(0, end).toDouble(),
                      max: end.toDouble(),
                      activeColor: const Color(0xFFF1D98F),
                      onChanged: (v) => _player.seek(
                          Duration(milliseconds: v.round())),
                    ),
                  ]);
                },
              )
            else if (_error == null)
              const LinearProgressIndicator(),
          ]),
        ),
        const SizedBox(height: 20),
        Text(ar ? 'النص الأصلي المطابق للتسجيل'
            : 'Official transcript matching this recording',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(ar
            ? 'هذا التسجيل من VOA مباشرة. افتح نصه الأصلي من المصدر نفسه؛ لم يتم اعتماد توقيت كل سطر بعد، لذلك لا نعرض تزامنًا وهميًا.'
            : 'This is the actual VOA conversation. Open its full original transcript at the source; line-by-line timing is not yet verified.',
            style: TextStyle(height: 1.6, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 13),
        FilledButton.icon(
          key: const ValueKey('voa-original-transcript-link'),
          onPressed: _openOfficialTranscript,
          icon: const Icon(Icons.open_in_new_rounded),
          label: Text(ar ? 'فتح النص الكامل في موقع VOA'
              : 'Open complete original transcript on VOA'),
        ),
        const SizedBox(height: 10),
        Text('VOA Learning English · Let\'s Learn English Level 1. WorldVoice is not affiliated with VOA.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
      ]),
    );
  }
}
