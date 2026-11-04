import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../domain/models/story_textbook_models.dart';

/// Local device TTS; no cloud or third-party speech service.
/// Uses distinct installed voices when available, pitch as fallback.
class StoryTextbookNarration extends ChangeNotifier {
  StoryTextbookNarration({FlutterTts? engine, this.language = 'en'})
      : _engine = engine ?? FlutterTts();

  final FlutterTts _engine;
  final String language;
  List<Map<String, String>>? _voices;
  List<StoryTextbookSegment> _queue = const [];
  void Function(int)? _onSegment;
  int _cursor = 0;
  int _generation = 0;
  bool _playing = false;
  bool _paused = false;
  bool _disposed = false;
  String? _error;
  double _speed = 0.46;

  bool get playing => _playing;
  bool get paused => _paused;
  int get currentSegment => _cursor;
  double get speed => _speed;
  String? get error => _error;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> changeSpeed(double speed) async {
    _speed = speed.clamp(0.2, 0.8);
    _notify();
    await _engine.setSpeechRate(_speed);
  }

  Future<void> _loadVoices() async {
    if (_voices != null) return;
    try {
      final available = await _engine.getVoices;
      if (available is List) {
        _voices = available.whereType<Map>().map((voice) {
          return {
            'name': (voice['name'] ?? '').toString(),
            'locale': (voice['locale'] ?? '').toString(),
            'gender': (voice['gender'] ?? '').toString().toLowerCase(),
          };
        }).where((voice) =>
            voice['name']!.isNotEmpty &&
            voice['locale']!.toLowerCase().startsWith(language.toLowerCase()))
            .toList(growable: false);
      } else {
        _voices = [];
      }
    } catch (_) {
      _voices = [];
    }
  }

  Future<void> _selectVoice(StoryTextbookSpeaker speaker) async {
    final locale = switch (language) {
      'en' => 'en-US',
      'fr' => 'fr-FR',
      'es' => 'es-ES',
      'zh' => 'zh-CN',
      'ko' => 'ko-KR',
      _ => language,
    };
    await _engine.setLanguage(locale);
    await _loadVoices();
    final candidates = _voices ?? [];
    Map<String, String>? voice;
    if (speaker == StoryTextbookSpeaker.female) {
      for (final entry in candidates) {
        if (entry['gender'] == 'female' ||
            entry['name']!.toLowerCase().contains('female')) {
          voice = entry;
          break;
        }
      }
    } else if (speaker == StoryTextbookSpeaker.male) {
      for (final entry in candidates) {
        if (entry['gender'] == 'male' ||
            entry['name']!.toLowerCase().contains('male')) {
          voice = entry;
          break;
        }
      }
    }
    if (voice == null && candidates.isNotEmpty) {
      final position = switch (speaker) {
        StoryTextbookSpeaker.narrator => 0,
        StoryTextbookSpeaker.female => 1,
        StoryTextbookSpeaker.male => 2,
      };
      voice = candidates[position % candidates.length];
    }
    if (voice != null) {
      await _engine.setVoice({
        'name': voice['name']!,
        'locale': voice['locale']!,
      });
    }
    await _engine.setPitch(switch (speaker) {
      StoryTextbookSpeaker.narrator => 1.0,
      StoryTextbookSpeaker.female => 1.12,
      StoryTextbookSpeaker.male => 0.88,
    });
    await _engine.setSpeechRate(_speed);
  }

  Future<void> play(
    List<StoryTextbookSegment> segments, {
    required void Function(int) onSegment,
  }) async {
    await stop();
    if (_disposed || segments.isEmpty) return;
    _queue = List.unmodifiable(segments);
    _onSegment = onSegment;
    _cursor = 0;
    _paused = false;
    _playing = true;
    _error = null;
    _notify();
    final generation = ++_generation;
    await _run(generation);
  }

  Future<void> _run(int generation) async {
    try {
      await _engine.awaitSpeakCompletion(true);
      while (!_disposed && _playing && generation == _generation &&
          _cursor < _queue.length) {
        final segment = _queue[_cursor];
        await _selectVoice(segment.speaker);
        if (_disposed || !_playing || generation != _generation) return;
        _onSegment?.call(_cursor);
        _notify();
        await _engine.speak(segment.speechText);
        if (_disposed || !_playing || generation != _generation) return;
        _cursor++;
      }
    } catch (_) {
      _error = 'Narration is unavailable on this device.';
    } finally {
      if (!_disposed && generation == _generation) {
        _playing = false;
        _paused = false;
        _notify();
      }
    }
  }

  Future<void> _safeStop() async {
    try {
      await _engine.stop();
    } catch (_) {
      // Disposing without a speech engine (e.g. in widget tests) is safe.
    }
  }

  Future<void> pause() async {
    if (!_playing) return;
    ++_generation;
    _playing = false;
    _paused = true;
    _notify();
    await _safeStop();
  }

  Future<void> resume() async {
    if (!_paused || _disposed || _queue.isEmpty) return;
    _paused = false;
    _playing = true;
    _notify();
    final generation = ++_generation;
    await _run(generation);
  }

  Future<void> stop() async {
    final wasActive = _playing || _paused;
    ++_generation;
    _playing = false;
    _paused = false;
    _queue = const [];
    _cursor = 0;
    _notify();
    if (wasActive) await _safeStop();
  }

  @override
  void dispose() {
    ++_generation;
    _disposed = true;
    unawaited(_safeStop());
    super.dispose();
  }
}
