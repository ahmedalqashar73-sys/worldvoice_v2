import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'agora_voice_room_controller.dart';
import 'room_caption_service.dart';

typedef RoomCaptionStateCallback = void Function({
  required bool listening,
  String? error,
});

typedef RoomCaptionTextCallback = void Function({
  required String text,
  required bool isLocal,
  required String languageCode,
  int? agoraUid,
});

class RoomLiveCaptionController {
  RoomLiveCaptionController({
    required RoomCaptionService service,
    required RoomCaptionStateCallback onState,
    Stream<AgoraRoomAudioFrame>? audioFrames,
    RoomCaptionTextCallback? onTranscript,
    void Function(String)? onProgress,
  }) : this._(service, onState, audioFrames, onTranscript, onProgress);

  RoomLiveCaptionController._(
    this._service,
    this._onState,
    this._audioFrames,
    this._onTranscript,
    this._onProgress,
  ) {
    if (_audioFrames != null) {
      _audioSub = _audioFrames.listen(
        _onAgoraFrame,
        onError: (Object error, StackTrace stackTrace) {
          if (_disposed) return;
          _onState(listening: false, error: error.toString());
        },
      );
    }
  }

  final RoomCaptionService _service;
  final RoomCaptionStateCallback _onState;
  final Stream<AgoraRoomAudioFrame>? _audioFrames;
  final RoomCaptionTextCallback? _onTranscript;
  final void Function(String)? _onProgress;

  final SpeechToText _speech = SpeechToText();
  final SpeechToText _localSpeech = SpeechToText();
  final Map<String, _PcmSpeechSegment> _segments =
      <String, _PcmSpeechSegment>{};
  final Set<String> _inFlight = <String>{};
  final Map<String, _PendingAudio> _pendingByKey =
      <String, _PendingAudio>{};
  final Map<String, String> _lastTranscriptByKey = <String, String>{};

  StreamSubscription<AgoraRoomAudioFrame>? _audioSub;
  Timer? _restartTimer;
  bool _initialized = false;
  bool _available = false;
  bool _localInitialized = false;
  bool _localAvailable = false;
  bool _localStarting = false;
  bool _enabled = false;
  bool _canPublish = false;
  bool _captureRemote = false;
  bool _useAgoraLocal = false;
  bool _playbackPaused = false;
  bool _receivedLocalFrame = false;

  void pauseForPlayback(bool paused) {
    _playbackPaused = paused;
    _generation++;
    _segments.clear();
    _pendingByKey.clear();
    if (_useAgoraLocal) _onState(listening: !paused && _enabled && _receivedLocalFrame);
  }
  bool _starting = false;
  bool _disposed = false;
  int _generation = 0;
  String _languageCode = 'en';
  String _displayName = 'WorldVoice user';
  String? _localeId;
  String? _localLocaleId;
  String _lastPublished = '';
  String _lastLocalPublished = '';
  String _pendingLocalText = '';
  Timer? _localResultTimer;

  bool get enabled => _enabled;
  bool get listening =>
      _audioFrames != null
          ? _enabled && ((_useAgoraLocal && _receivedLocalFrame && !_playbackPaused) || _localSpeech.isListening || _captureRemote)
          : _speech.isListening;
  bool get available => _audioFrames != null ? true : _available;

  Future<void> configure({
    required bool enabled,
    required bool canPublish,
    required String languageCode,
    required String displayName,
    bool captureRemote = false,
    bool useAgoraLocal = false,
  }) async {
    if (_disposed) return;
    final nextLanguage = languageCode.trim().isEmpty ? 'en' : languageCode.toLowerCase();
    final nextAgoraLocal = useAgoraLocal && _audioFrames != null;
    final changed = enabled != _enabled || canPublish != _canPublish ||
        captureRemote != _captureRemote || nextAgoraLocal != _useAgoraLocal ||
        nextLanguage != _languageCode;
    if (changed) {
      _generation++;
      _segments.clear();
      _pendingByKey.clear();
    }
    if (nextAgoraLocal != _useAgoraLocal) {
      _receivedLocalFrame = false;
      _segments.clear();
      _pendingByKey.clear();
      _lastTranscriptByKey.clear();
    }
    _useAgoraLocal = nextAgoraLocal;
    _enabled = enabled;
    _canPublish = canPublish;
    _captureRemote = captureRemote;
    final languageChanged = _languageCode != nextLanguage;
    _languageCode = nextLanguage;
    if (languageChanged) {
      _lastLocalPublished = '';
      _lastPublished = '';
      _lastTranscriptByKey.clear();
      _pendingLocalText = '';
      _localResultTimer?.cancel();
      // Language changes must update the device recognizer locale too.
      if (_localInitialized && _localAvailable) {
        _localLocaleId = await _findSpeechLocale(_localSpeech, _languageCode);
        if (_localSpeech.isListening) await _localSpeech.stop();
      }
      if (_initialized && _available) {
        _localeId = await _findSpeechLocale(_speech, _languageCode);
        if (_speech.isListening) await _speech.stop();
      }
    }
    _displayName = displayName.trim().isEmpty
        ? 'WorldVoice user'
        : displayName.trim();

    if (_audioFrames != null) {
      if (!_enabled || (!_canPublish && !_captureRemote)) {
        _segments.clear();
        _pendingByKey.clear();
        if (_localSpeech.isListening) {
          await _localSpeech.stop();
        }
        _onState(listening: false);
        return;
      }

      if (_useAgoraLocal) {
        _restartTimer?.cancel();
        _localResultTimer?.cancel();
        _pendingLocalText = '';
        // Reuse Agora's microphone. Android's second recorder can receive
        // silence while Agora owns the active communication microphone.
        if (_localSpeech.isListening) await _localSpeech.cancel();
        _onState(listening: _receivedLocalFrame && !_playbackPaused);
        return;
      }

      // Local speech must not depend on the paid transcription backend.
      // Android's recognizer handles the host/speaker locally, while Agora
      // PCM remains available for remote speakers.
      if (_canPublish) {
        await _startLocalSpeechIfNeeded();
      } else if (_localSpeech.isListening) {
        await _localSpeech.stop();
      }
      _onState(listening: _localSpeech.isListening || _captureRemote);
      return;
    }

    if (!_enabled || !_canPublish) {
      _restartTimer?.cancel();
      if (_speech.isListening) {
        await _speech.stop();
      }
      _onState(listening: false);
      return;
    }

    await _startIfNeeded();
  }

  void _onAgoraFrame(AgoraRoomAudioFrame frame) {
    if (_disposed || !_enabled) return;
    if (frame.isLocal) {
      if (!_useAgoraLocal || !_canPublish || _playbackPaused) return;
      if (!_receivedLocalFrame) {
        _receivedLocalFrame = true;
        _onState(listening: true);
      }
    } else if (!_captureRemote) {
      return;
    }

    final uid = frame.agoraUid;
    if (!frame.isLocal && (uid == null || uid <= 0)) return;

    final key = frame.isLocal ? 'local' : 'remote:$uid';
    final segment = _segments.putIfAbsent(
      key,
      () => _PcmSpeechSegment(
        sampleRate: frame.sampleRate,
        channels: frame.channels,
      ),
    );

    final completed = segment.add(frame.bytes);
    if (completed == null) return;

    _queueTranscription(
      key: key,
      audio: completed,
      isLocal: frame.isLocal,
      agoraUid: uid,
    );
  }

  void _queueTranscription({
    required String key,
    required _CompletedPcmSegment audio,
    required bool isLocal,
    required int? agoraUid,
  }) {
    if (audio.bytes.length < audio.bytesPerSecond ~/ 2) {
      return;
    }

    final pending = _PendingAudio(
      bytes: audio.bytes,
      sampleRate: audio.sampleRate,
      channels: audio.channels,
      isLocal: isLocal,
      agoraUid: agoraUid,
      generation: _generation,
    );

    if (_inFlight.contains(key)) {
      // Keep only the newest completed phrase while an earlier phrase is
      // being transcribed. This avoids unbounded network/audio queues.
      _pendingByKey[key] = pending;
      return;
    }

    unawaited(_submit(key, pending));
  }

  Future<void> _submit(String key, _PendingAudio pending) async {
    _inFlight.add(key);
    try {
      final wav = _wav(
        pending.bytes,
        sampleRate: pending.sampleRate,
        channels: pending.channels,
      );
      _onProgress?.call('Recognizing your speech…');
      final text = await _service.transcribeWav(wav, languageCode: _languageCode);
      if (_disposed || pending.generation != _generation) return;
      if (text.trim().isEmpty) {
        _onProgress?.call('No words recognized. Please speak again.');
        return;
      }

      final normalized = text.trim();
      if (!_useAgoraLocal && _lastTranscriptByKey[key] == normalized) return;
      _lastTranscriptByKey[key] = normalized;

      final callback = _onTranscript;
      if (callback != null) {
        callback(
          text: normalized,
          isLocal: pending.isLocal,
          agoraUid: pending.agoraUid,
          languageCode: _languageCode,
        );
      } else if (pending.isLocal) {
        await _service.publishFinal(
          displayName: _displayName,
          text: normalized,
          languageCode: _languageCode,
        );
      }
      _onState(listening: true);
    } catch (error) {
      if (!_disposed && pending.generation == _generation) {
        _onState(
          listening: _enabled,
          error: error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      _inFlight.remove(key);
      final next = _pendingByKey.remove(key);
      if (next != null && !_disposed && next.generation == _generation) {
        unawaited(_submit(key, next));
      }
    }
  }

  Uint8List _wav(
    Uint8List pcm, {
    required int sampleRate,
    required int channels,
  }) {
    final safeRate = sampleRate > 0 ? sampleRate : 16000;
    final safeChannels = channels == 2 ? 2 : 1;
    const bitsPerSample = 16;
    final byteRate = safeRate * safeChannels * bitsPerSample ~/ 8;
    final blockAlign = safeChannels * bitsPerSample ~/ 8;
    final dataLength = pcm.length;
    final bytes = ByteData(44 + dataLength);

    void ascii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        bytes.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    bytes.setUint32(4, 36 + dataLength, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, safeChannels, Endian.little);
    bytes.setUint32(24, safeRate, Endian.little);
    bytes.setUint32(28, byteRate, Endian.little);
    bytes.setUint16(32, blockAlign, Endian.little);
    bytes.setUint16(34, bitsPerSample, Endian.little);
    ascii(36, 'data');
    bytes.setUint32(40, dataLength, Endian.little);
    bytes.buffer.asUint8List(44).setAll(0, pcm);
    return bytes.buffer.asUint8List();
  }

  Future<String?> _findSpeechLocale(
    SpeechToText recognizer,
    String language,
  ) async {
    final locales = await recognizer.locales();
    final normalized = language.toLowerCase().split(RegExp(r'[-_]')).first;
    for (final locale in locales) {
      final code = locale.localeId.toLowerCase().split(RegExp(r'[-_]')).first;
      if (code == normalized) return locale.localeId;
    }
    // Let the engine choose its default when the target is unsupported.
    return null;
  }

  Future<void> _initializeLocalSpeech() async {
    if (_localInitialized || _disposed) return;
    _localInitialized = true;

    _localAvailable = await _localSpeech.initialize(
      onStatus: (status) {
        if (_disposed || _audioFrames == null || _useAgoraLocal) return;
        final listening = status == SpeechToText.listeningStatus;
        _onState(listening: listening || (_enabled && _captureRemote));
        if (status == SpeechToText.doneStatus ||
            status == SpeechToText.notListeningStatus) {
          _scheduleLocalRestart();
        }
      },
      onError: (error) {
        if (_disposed || _useAgoraLocal) return;
        _onState(
          listening: _enabled && _captureRemote,
          error: error.errorMsg,
        );
        _scheduleLocalRestart();
      },
    );

    if (!_localAvailable) {
      _onState(
        listening: _enabled && _captureRemote,
        error: 'Speech recognition is not available on this device.',
      );
      return;
    }

    _localLocaleId = await _findSpeechLocale(_localSpeech, _languageCode);
  }

  Future<void> _startLocalSpeechIfNeeded() async {
    if (_disposed ||
        _audioFrames == null ||
        _useAgoraLocal ||
        !_enabled ||
        !_canPublish ||
        _localStarting ||
        _localSpeech.isListening) {
      return;
    }

    _localStarting = true;
    try {
      await _initializeLocalSpeech();
      if (!_localAvailable || _disposed || _useAgoraLocal || !_enabled || !_canPublish) return;

      await _localSpeech.listen(
        onResult: (result) {
          if (_disposed || _useAgoraLocal || !_enabled || !_canPublish) return;
          final text = result.recognizedWords.trim();
          if (text.isEmpty || text == _lastLocalPublished) return;

          _pendingLocalText = text;
          _localResultTimer?.cancel();

          if (result.finalResult) {
            _emitLocalTranscript(text);
            return;
          }

          // Live speech often does not emit a final result quickly while
          // the speaker keeps talking. Publish the latest stable partial
          // result after a short quiet window so subtitles feel live.
          _localResultTimer = Timer(
            const Duration(milliseconds: 650),
            () => _emitLocalTranscript(_pendingLocalText),
          );
        },
        listenOptions: SpeechListenOptions(
          cancelOnError: false,
          partialResults: true,
          listenMode: ListenMode.dictation,
          autoPunctuation: true,
          pauseFor: const Duration(seconds: 2),
          listenFor: const Duration(seconds: 60),
          localeId: _localLocaleId,
        ),
      );
    } catch (error) {
      if (!_disposed) {
        _onState(
          listening: _enabled && _captureRemote,
          error: error.toString(),
        );
        _scheduleLocalRestart();
      }
    } finally {
      _localStarting = false;
    }
  }

  void _emitLocalTranscript(String text) {
    if (_disposed || _useAgoraLocal || !_enabled || !_canPublish) return;
    final normalized = text.trim();
    if (normalized.isEmpty || normalized == _lastLocalPublished) return;

    _lastLocalPublished = normalized;
    final callback = _onTranscript;
    if (callback != null) {
      callback(
        text: normalized,
        isLocal: true,
        languageCode: _languageCode,
        agoraUid: null,
      );
      return;
    }

    unawaited(
      _service.publishFinal(
        displayName: _displayName,
        text: normalized,
        languageCode: _languageCode,
      ),
    );
  }

  void _scheduleLocalRestart() {
    if (_audioFrames == null ||
        _useAgoraLocal ||
        _disposed ||
        !_enabled ||
        !_canPublish) {
      return;
    }
    _restartTimer?.cancel();
    _restartTimer = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(_startLocalSpeechIfNeeded()),
    );
  }

  Future<void> _initialize() async {
    if (_initialized || _disposed) return;
    _initialized = true;

    _available = await _speech.initialize(
      onStatus: _handleStatus,
      onError: (error) {
        if (_disposed) return;
        _onState(
          listening: false,
          error: error.errorMsg,
        );
        _scheduleRestart();
      },
    );

    if (!_available) {
      _onState(
        listening: false,
        error: 'Speech recognition is not available on this device.',
      );
      return;
    }

    _localeId = await _findSpeechLocale(_speech, _languageCode);
  }

  Future<void> _startIfNeeded() async {
    if (_disposed ||
        !_enabled ||
        !_canPublish ||
        _starting ||
        _speech.isListening) {
      return;
    }

    _starting = true;
    try {
      await _initialize();
      if (!_available || _disposed || !_enabled || !_canPublish) return;

      await _speech.listen(
        onResult: _onSpeechResult,
        listenOptions: SpeechListenOptions(
          cancelOnError: false,
          partialResults: true,
          listenMode: ListenMode.dictation,
          autoPunctuation: true,
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 25),
          localeId: _localeId,
        ),
      );

      if (!_disposed) {
        _onState(listening: _speech.isListening);
      }
    } catch (error) {
      if (!_disposed) {
        _onState(
          listening: false,
          error: error.toString(),
        );
        _scheduleRestart();
      }
    } finally {
      _starting = false;
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (_disposed || _useAgoraLocal || !_enabled || !_canPublish) return;
    final text = result.recognizedWords.trim();
    if (!result.finalResult || text.isEmpty || text == _lastPublished) {
      return;
    }

    _lastPublished = text;
    final callback = _onTranscript;
    if (callback != null) {
      callback(
        text: text,
        isLocal: true,
        languageCode: _languageCode,
        agoraUid: null,
      );
      return;
    }

    unawaited(
      _service.publishFinal(
        displayName: _displayName,
        text: text,
        languageCode: _languageCode,
      ),
    );
  }

  void _handleStatus(String status) {
    if (_disposed) return;
    _onState(listening: status == SpeechToText.listeningStatus);
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _scheduleRestart();
    }
  }

  void _scheduleRestart() {
    if (_audioFrames != null ||
        _disposed ||
        !_enabled ||
        !_canPublish) {
      return;
    }
    _restartTimer?.cancel();
    _restartTimer = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(_startIfNeeded()),
    );
  }

  Future<void> dispose() async {
    _disposed = true;
    _generation++;
    _restartTimer?.cancel();
    _localResultTimer?.cancel();
    await _audioSub?.cancel();
    _segments.clear();
    _pendingByKey.clear();
    if (_speech.isListening) {
      await _speech.cancel();
    }
    if (_localSpeech.isListening) {
      await _localSpeech.cancel();
    }
  }
}

class _PcmSpeechSegment {
  _PcmSpeechSegment({
    required this.sampleRate,
    required this.channels,
  });

  final int sampleRate;
  final int channels;
  final Queue<Uint8List> _preRoll = Queue<Uint8List>();
  final BytesBuilder _active = BytesBuilder(copy: false);
  int _preRollBytes = 0;
  int _speechMs = 0;
  int _silenceMs = 0;
  bool _speaking = false;

  int get bytesPerSecond =>
      (sampleRate > 0 ? sampleRate : 16000) *
      (channels == 2 ? 2 : 1) *
      2;

  _CompletedPcmSegment? add(Uint8List frame) {
    if (frame.isEmpty) return null;
    final frameMs =
        ((frame.length / bytesPerSecond) * 1000).round().clamp(1, 200).toInt();
    final level = _meanAbsolutePcm16(frame);
    const speechStartLevel = 320;
    const silenceLevel = 190;

    if (!_speaking) {
      _preRoll.addLast(frame);
      _preRollBytes += frame.length;
      final maxPreRoll = (bytesPerSecond * 0.24).round();
      while (_preRollBytes > maxPreRoll && _preRoll.isNotEmpty) {
        _preRollBytes -= _preRoll.removeFirst().length;
      }

      if (level < speechStartLevel) return null;

      _speaking = true;
      for (final chunk in _preRoll) {
        _active.add(chunk);
      }
      _preRoll.clear();
      _preRollBytes = 0;
      _speechMs = frameMs;
      _silenceMs = 0;
      return null;
    }

    _active.add(frame);
    _speechMs += frameMs;
    if (level < silenceLevel) {
      _silenceMs += frameMs;
    } else {
      _silenceMs = 0;
    }

    final phraseEnded = _silenceMs >= 650 && _speechMs >= 500;
    final maxReached = _speechMs >= 7000;
    if (!phraseEnded && !maxReached) return null;

    return _finish();
  }

  _CompletedPcmSegment _finish() {
    final bytes = _active.takeBytes();
    final result = _CompletedPcmSegment(
      bytes: bytes,
      sampleRate: sampleRate,
      channels: channels,
    );
    _speaking = false;
    _speechMs = 0;
    _silenceMs = 0;
    _preRoll.clear();
    _preRollBytes = 0;
    return result;
  }

  int _meanAbsolutePcm16(Uint8List bytes) {
    if (bytes.length < 2) return 0;
    var total = 0;
    var count = 0;
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      var sample = bytes[i] | (bytes[i + 1] << 8);
      if (sample >= 0x8000) sample -= 0x10000;
      total += sample.abs();
      count++;
    }
    return count == 0 ? 0 : total ~/ count;
  }
}

class _CompletedPcmSegment {
  const _CompletedPcmSegment({
    required this.bytes,
    required this.sampleRate,
    required this.channels,
  });

  final Uint8List bytes;
  final int sampleRate;
  final int channels;

  int get bytesPerSecond =>
      (sampleRate > 0 ? sampleRate : 16000) *
      (channels == 2 ? 2 : 1) *
      2;
}

class _PendingAudio {
  const _PendingAudio({
    required this.bytes,
    required this.sampleRate,
    required this.channels,
    required this.isLocal,
    required this.agoraUid,
    required this.generation,
  });

  final Uint8List bytes;
  final int sampleRate;
  final int channels;
  final bool isLocal;
  final int? agoraUid;
  final int generation;
}
