import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Machine-generated candidates based on the exact 30-minute VOA MP3.
/// These are NOT editorially verified or word-accurate subtitles.
class B1VoaCaptionLine {
  const B1VoaCaptionLine({
    required this.startMs,
    required this.endMs,
    required this.english,
    required this.arabic,
  });

  final int startMs;
  final int endMs;
  final String english;
  final String arabic;

  factory B1VoaCaptionLine.fromJson(Map<String, dynamic> value) {
    return B1VoaCaptionLine(
      startMs: value['start_ms'] as int,
      endMs: value['end_ms'] as int,
      english: value['text'] as String,
      arabic: value['translation_ar'] as String,
    );
  }
}

class B1VoaTranscript {
  const B1VoaTranscript({
    required this.id,
    required this.audioUrl,
    required this.measuredDurationMs,
    required this.lines,
    required this.isMachineDraft,
  });

  final String id;
  final String audioUrl;
  final int measuredDurationMs;
  final List<B1VoaCaptionLine> lines;
  final bool isMachineDraft;

  static B1VoaTranscript fromJson(Map<String, dynamic> value) {
    if (value['level'] != 'B1' ||
        value['transcript_status'] != 'machine_draft_review_required' ||
        value['translation_status'] != 'machine_draft_review_required' ||
        value['sync_status'] != 'unverified' ||
        value['approved_for_publication'] != false) {
      throw const FormatException('Unexpected B1 transcript provenance');
    }
    final duration = value['measured_duration_ms'] as int;
    if (duration < 600000 || duration > 3600000) {
      throw const FormatException('Invalid original B1 audio duration');
    }
    final candidates = (value['dialogue'] as List<dynamic>)
        .map((line) => B1VoaCaptionLine.fromJson(
            line as Map<String, dynamic>))
        .toList(growable: false);
    if (candidates.length < 20) {
      throw const FormatException('Too few original B1 audio captions');
    }
    var previousStart = -1;
    for (final line in candidates) {
      if (line.startMs < 0 ||
          line.startMs < previousStart ||
          line.endMs <= line.startMs ||
          line.endMs > duration + 3000 ||
          line.english.trim().isEmpty ||
          line.arabic.trim().isEmpty) {
        throw const FormatException('Invalid B1 bilingual audio cue');
      }
      previousStart = line.startMs;
    }
    return B1VoaTranscript(
      id: value['id'] as String,
      audioUrl: value['audio_url'] as String,
      measuredDurationMs: duration,
      lines: candidates,
      isMachineDraft: true,
    );
  }

  int indexAt(Duration position) {
    if (lines.isEmpty) return -1;
    var low = 0;
    var high = lines.length;
    final t = position.inMilliseconds;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (lines[mid].startMs <= t) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    final index = low - 1;
    if (index < 0 || t > lines[index].endMs + 1000) return -1;
    return index;
  }
}

class B1VoaTranscriptRepository {
  const B1VoaTranscriptRepository();

  static const String assetPath =
      'assets/podcasts/voa_english_b1_transcripts.json';

  // One original 30-episode transcript asset is shared by the list and
  // player. Cache the decoded JSON to avoid repeatedly parsing all 30
  // half-hour transcripts when a learner changes episode.
  static Future<Map<String, dynamic>?>? _sharedDocument;

  static Future<Map<String, dynamic>?> _loadDocument() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['schema'] != 1 ||
          data['language'] != 'en' ||
          data['level'] != 'B1' ||
          data['episode_count'] != 30 ||
          (data['episodes'] as List<dynamic>).length != 30) {
        throw const FormatException('Unexpected B1 caption catalog');
      }
      return data;
    } on FlutterError {
      // Original audio remains available even on builds without captions.
      return null;
    }
  }

  Future<Set<String>> availableIds() async {
    final data = await (_sharedDocument ??= _loadDocument());
    if (data == null) return <String>{};
    return (data['episodes'] as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['id'] as String)
        .toSet();
  }

  Future<B1VoaTranscript?> loadFor({
    required String episodeId,
    required String audioUrl,
  }) async {
    final data = await (_sharedDocument ??= _loadDocument());
    if (data == null) return null;
    final episodes = data['episodes'] as List<dynamic>;
    for (final candidate in episodes) {
      final value = candidate as Map<String, dynamic>;
      if (value['id'] == episodeId) {
        if (value['audio_url'] != audioUrl) {
          throw const FormatException('Transcript and audio URL mismatch');
        }
        return B1VoaTranscript.fromJson(value);
      }
    }
    return null;
  }
}

/// This panel displays an explicitly labelled machine draft, synchronized
/// using audio-derived candidate cue times, not fabricated word-count offsets.
class B1VoaCaptionPanel extends StatefulWidget {
  const B1VoaCaptionPanel({
    super.key,
    required this.transcript,
    required this.position,
    required this.onSeek,
  });

  final B1VoaTranscript transcript;
  final Duration position;
  final ValueChanged<Duration> onSeek;

  @override
  State<B1VoaCaptionPanel> createState() => _B1VoaCaptionPanelState();
}

class _B1VoaCaptionPanelState extends State<B1VoaCaptionPanel> {
  final ScrollController _controller = ScrollController();
  final Map<int, GlobalKey> _rowKeys = {};
  bool _showArabic = true;
  bool _autoScroll = true;
  int _lastLine = -2;

  @override
  void initState() {
    super.initState();
    _lastLine = widget.transcript.indexAt(widget.position);
  }

  @override
  void didUpdateWidget(covariant B1VoaCaptionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transcript.id != widget.transcript.id) {
      _rowKeys.clear();
      _lastLine = -2;
    }
    final index = widget.transcript.indexAt(widget.position);
    if (index != _lastLine) {
      _lastLine = index;
      if (_autoScroll && index >= 0) _scrollToLine(index);
    }
  }

  // Caption lengths vary widely: a fixed item height clipped the real
  // English and Arabic text. Scroll to the actual rendered paragraph instead
  // of assuming that every line is exactly 160 pixels tall.
  void _scrollToLine(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_autoScroll || !_controller.hasClients) return;
      void revealIfMounted() {
        final rowContext = _rowKeys[index]?.currentContext;
        if (mounted && _autoScroll && rowContext != null) {
          Scrollable.ensureVisible(rowContext,
              alignment: 0.25,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut);
        }
      }
      if (_rowKeys[index]?.currentContext != null) {
        revealIfMounted();
      } else {
        // A large seek may target an off-screen lazy-built row. Jump near
        // the target and refine once it has been laid out.
        final extent = _controller.position.maxScrollExtent;
        final fraction = widget.transcript.lines.length > 1
            ? index / (widget.transcript.lines.length - 1)
            : 0.0;
        _controller.jumpTo((extent * fraction).clamp(0.0, extent));
        WidgetsBinding.instance.addPostFrameCallback((_) => revealIfMounted());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final active = widget.transcript.indexAt(widget.position);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.subtitles_rounded, color: Color(0xFF20845C)),
        const SizedBox(width: 8),
        Expanded(child: Text(
          ar ? 'النص الإنجليزي والترجمة العربية'
              : 'English captions and Arabic translation',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        )),
      ]),
      const SizedBox(height: 7),
      Text(
        ar
            ? 'مسودة تفريغ وترجمة آلية من التسجيل الأصلي. توقيت الجمل تقريبي ويحتاج مراجعة؛ اضغط الجملة للانتقال إليها.'
            : 'Automatic transcript and translation draft from the original audio. Approximate line timing needs review; tap a line to seek.',
        style: TextStyle(fontSize: 12, height: 1.5,
            color: scheme.onSurfaceVariant),
      ),
      Row(children: [
        Checkbox(
          value: _showArabic,
          onChanged: (v) => setState(() => _showArabic = v ?? true),
        ),
        Text(ar ? 'إظهار الترجمة العربية' : 'Show Arabic translation'),
        const Spacer(),
        IconButton(
          tooltip: ar ? 'التمرير التلقائي' : 'Auto scroll',
          onPressed: () => setState(() => _autoScroll = !_autoScroll),
          icon: Icon(_autoScroll
              ? Icons.sync_rounded : Icons.sync_disabled_rounded),
        ),
      ]),
      if (active >= 0) ...[
        Container(
          key: const ValueKey('b1-active-caption'),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border(bottom: BorderSide(color: scheme.primary, width: 2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.transcript.lines[active].english,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 15,
                  fontWeight: FontWeight.bold)),
            if (_showArabic) ...[
              const SizedBox(height: 6),
              Text(widget.transcript.lines[active].arabic,
                textDirection: TextDirection.rtl),
            ],
          ]),
        ),
        const SizedBox(height: 8),
      ],
      SizedBox(
        height: 350,
        child: ListView.builder(
          key: const ValueKey('b1-bilingual-captions'),
          controller: _controller,
          itemCount: widget.transcript.lines.length,
          itemBuilder: (context, i) {
            final item = widget.transcript.lines[i];
            final selected = i == active;
            final completed = item.endMs < widget.position.inMilliseconds;
            return Padding(
              key: _rowKeys.putIfAbsent(i, () => GlobalKey()),
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  key: ValueKey('b1-caption-line-$i'),
                  onTap: () => widget.onSeek(
                      Duration(milliseconds: item.startMs)),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\u25b6 ${Duration(milliseconds: item.startMs).inMinutes.toString().padLeft(2, '0')}:${((item.startMs ~/ 1000) % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 11, color: scheme.primary,
                            fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text(item.english,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w800 : FontWeight.normal)),
                        if (_showArabic) ...[
                          const SizedBox(height: 3),
                          Text(item.arabic,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(fontSize: 13, height: 1.4)),
                        ],
                        if (selected || completed) ...[
                          const SizedBox(height: 7),
                          Container(
                            height: selected ? 2 : 1,
                            color: selected ? scheme.primary
                                : scheme.outlineVariant,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
