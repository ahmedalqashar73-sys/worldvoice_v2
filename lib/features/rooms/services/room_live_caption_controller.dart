import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'room_caption_service.dart';

typedef RoomCaptionStateCallback = void Function({
  required bool listening,
  String? error,
});

class RoomLiveCaptionController {
  RoomLiveCaptionController({
    required RoomCaptionService service,
    required RoomCaptionStateCallback onState,
  })  : _service = service,
        _onState = onState;

  final RoomCaptionService _service;
  final RoomCaptionStateCallback _onState;
  final SpeechToText _speech = SpeechToText();

  Timer? _restartTimer;
  bool _initialized = false;
  bool _available = false;
  bool _enabled = false;
  bool _canPublish = false;
  bool _starting = false;
  bool _disposed = false;
  String _languageCode = 'en';
  String _displayName = 'WorldVoice user';
  String? _localeId;
  String _lastPublished = '';

  bool get enabled => _enabled;
  bool get listening => _speech.isListening;
  bool get available => _available;

  Future<void> configure({
    required bool enabled,
    required bool canPublish,
    required String languageCode,
    required String displayName,
  }) async {
    _enabled = enabled;
    _canPublish = canPublish;
    _languageCode =
        languageCode.trim().isEmpty ? 'en' : languageCode.toLowerCase();
    _displayName = displayName.trim().isEmpty
        ? 'WorldVoice user'
        : displayName.trim();

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

    final locales = await _speech.locales();
    final normalized = _languageCode.toLowerCase();
    for (final locale in locales) {
      final localeCode =
          locale.localeId.toLowerCase().split(RegExp('[-_]')).first;
      if (localeCode == normalized) {
        _localeId = locale.localeId;
        break;
      }
    }
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
    if (_disposed || !_enabled || !_canPublish) return;
    final text = result.recognizedWords.trim();
    if (!result.finalResult || text.isEmpty || text == _lastPublished) {
      return;
    }

    _lastPublished = text;
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
    if (_disposed || !_enabled || !_canPublish) return;
    _restartTimer?.cancel();
    _restartTimer = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(_startIfNeeded()),
    );
  }

  Future<void> dispose() async {
    _disposed = true;
    _restartTimer?.cancel();
    if (_speech.isListening) {
      await _speech.cancel();
    }
  }
}
