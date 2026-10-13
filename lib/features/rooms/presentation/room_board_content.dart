import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/board_media_cache.dart';
import 'board_media_error.dart';

class BoardTextInput extends StatefulWidget {
  const BoardTextInput({required this.onSave, required this.onClose, super.key});
  final Future<void> Function(String) onSave;
  final VoidCallback onClose;
  @override
  State<BoardTextInput> createState() => _BoardTextInputState();
}

class _BoardTextInputState extends State<BoardTextInput> {
  final _controller = TextEditingController();
  bool _saving = false;
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  Future<void> _save(String value) async {
    if (_saving || value.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(value.trim());
      if (mounted) { FocusScope.of(context).unfocus(); widget.onClose(); }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          Localizations.localeOf(context).languageCode == 'ar' ? 'تعذر حفظ النص، حاول مجددًا' : 'Could not save text. Please retry.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller, autofocus: true, enabled: !_saving,
    maxLength: 300, textInputAction: TextInputAction.done, onSubmitted: _save,
    style: const TextStyle(color: Colors.white, fontSize: 18),
    decoration: InputDecoration(counterText: '', filled: true, fillColor: const Color(0xFF164A38),
      hintText: Localizations.localeOf(context).languageCode == 'ar' ? 'اكتب ثم اضغط تم' : 'Type, then press Done',
      suffixIcon: IconButton(onPressed: _saving ? null : () => _save(_controller.text),
        icon: const Icon(Icons.check, color: Color(0xFFE7C56E)))),
  );
}

class BoardVideo extends StatefulWidget {
  const BoardVideo({
    required this.url,
    required this.isHost,
    required this.playing,
    required this.positionMs,
    required this.onPlaybackChange,
    this.playbackChangedAt,
    super.key,
  });

  final String url;
  final bool isHost;
  final bool playing;
  final int positionMs;
  final Timestamp? playbackChangedAt;
  final Future<void> Function(bool playing, int positionMs) onPlaybackChange;

  @override
  State<BoardVideo> createState() => _BoardVideoState();
}

class _BoardVideoState extends State<BoardVideo> {
  late VideoPlayerController _player;
  bool _disposed = false;
  bool _ready = false;
  int _syncVersion = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    unawaited(_initialize());
  }

  @override
  void didUpdateWidget(covariant BoardVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isHost &&
        (oldWidget.playing != widget.playing ||
         oldWidget.positionMs != widget.positionMs ||
         oldWidget.playbackChangedAt != widget.playbackChangedAt)) {
      unawaited(_applyPlaybackState());
    }
  }

  Future<void> _initialize() async {
    File? cached;
    try {
      cached = await BoardMediaCache.cachedFileIfPresent(widget.url, 'video');
    } catch (_) {
      // A local cache miss must not prevent a shared video from opening.
    }
    if (_disposed) return;
    if (cached != null) {
      await _player.dispose();
      if (_disposed) return;
      _player = VideoPlayerController.file(cached);
    }
    try {
      await _player.initialize();
      if (cached == null && !_disposed) {
        unawaited(BoardMediaCache.getFile(widget.url, 'video')
            .then((_) {})
            .catchError((Object _) {}));
      }
    } catch (error) {
      final fallback = compatibleBoardVideoUrl(widget.url) ?? widget.url;
      if (_disposed) return;
      await _player.dispose();
      if (_disposed) return;
      _player = VideoPlayerController.networkUrl(Uri.parse(fallback));
      try {
        await _player.initialize();
      } catch (fallbackError) {
        _error = '$error\n$fallbackError';
      }
    }
    if (_disposed) return;
    if (_error == null) {
      _ready = true;
      await _applyPlaybackState();
    }
    if (mounted) setState(() {});
  }

  // Each device derives the current playback position from the latest
  // server-timestamped host command, so late joiners see the active video.
  Future<void> _applyPlaybackState() async {
    if (_disposed || !_ready) return;
    final version = ++_syncVersion;
    try {
      if (!widget.isHost) {
        final elapsedMs = widget.playing && widget.playbackChangedAt != null
            ? DateTime.now()
                .difference(widget.playbackChangedAt!.toDate())
                .inMilliseconds
            : 0;
        final durationMs = _player.value.duration.inMilliseconds;
        final requestedMs = widget.positionMs +
            (elapsedMs > 0 ? elapsedMs : 0);
        final targetMs = durationMs > 0
            ? requestedMs.clamp(0, durationMs).toInt()
            : requestedMs.clamp(0, 2147483647).toInt();
        final drift = (_player.value.position.inMilliseconds - targetMs).abs();
        if (drift > 1200) {
          await _player.seekTo(Duration(milliseconds: targetMs));
        }
      }
      if (_disposed || version != _syncVersion) return;
      if (widget.playing) {
        await _player.play();
      } else {
        await _player.pause();
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _publishPlayback({
    required bool playing,
    required int positionMs,
  }) async {
    if (!widget.isHost || _disposed || !_ready) return;
    try {
      if (playing) {
        await _player.play();
      } else {
        await _player.pause();
      }
      await widget.onPlaybackChange(playing, positionMs);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not synchronize video: $error'),
        ));
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _syncVersion++;
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    if (_error != null) {
      return BoardMediaError(url: widget.url, error: _error!);
    }
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _player,
      builder: (context, value, _) {
        if (value.hasError) {
          return BoardMediaError(
            url: widget.url,
            error: value.errorDescription ?? 'Video playback failed',
          );
        }
        if (!value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }
        return LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxHeight < 80) {
            return Center(
              child: IconButton(
                onPressed: widget.isHost
                    ? () => _publishPlayback(
                        playing: !value.isPlaying,
                        positionMs: value.position.inMilliseconds,
                      )
                    : null,
                icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
              ),
            );
          }
          final durationMs = value.duration.inMilliseconds;
          final positionMs = value.position.inMilliseconds;
          return Column(children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: value.aspectRatio,
                  child: VideoPlayer(_player),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: Row(children: [
                IconButton(
                  tooltip: ar ? 'تشغيل / إيقاف' : 'Play / pause',
                  onPressed: widget.isHost
                      ? () => _publishPlayback(
                          playing: !value.isPlaying,
                          positionMs: positionMs,
                        )
                      : null,
                  icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                Expanded(
                  child: Slider(
                    min: 0,
                    max: durationMs > 0 ? durationMs.toDouble() : 1,
                    value: durationMs > 0
                        ? positionMs.clamp(0, durationMs).toDouble()
                        : 0,
                    onChanged: widget.isHost && durationMs > 0
                        ? (next) => _player.seekTo(
                            Duration(milliseconds: next.round()))
                        : null,
                    onChangeEnd: widget.isHost && durationMs > 0
                        ? (next) => _publishPlayback(
                            playing: _player.value.isPlaying,
                            positionMs: next.round(),
                          )
                        : null,
                  ),
                ),
                IconButton(
                  tooltip: ar ? 'صوت الفيديو' : 'Video sound',
                  onPressed: () =>
                      _player.setVolume(value.volume == 0 ? 1 : 0),
                  icon: Icon(value.volume == 0
                      ? Icons.volume_off : Icons.volume_up),
                ),
              ]),
            ),
          ]);
        });
      },
    );
  }
}


/// A PDF opened in a room is downloaded into app-private persistent storage
/// once; repeated openings reuse that local file and avoid network spinners.
class CachedBoardPdf extends StatefulWidget {
  const CachedBoardPdf({required this.url, super.key});
  final String url;

  @override
  State<CachedBoardPdf> createState() => _CachedBoardPdfState();
}

class _CachedBoardPdfState extends State<CachedBoardPdf> {
  late Future<File> _file;

  @override
  void initState() {
    super.initState();
    _file = BoardMediaCache.getFile(widget.url, 'pdf');
  }

  @override
  void didUpdateWidget(covariant CachedBoardPdf oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _file = BoardMediaCache.getFile(widget.url, 'pdf');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: _file,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return PdfViewer.file(
            snapshot.data!.path,
            params: PdfViewerParams(
              errorBannerBuilder: (context, error, stack, document) =>
                  BoardMediaError(
                url: widget.url,
                error: error.toString(),
                onRetry: () => setState(
                  () => _file = BoardMediaCache.getFile(widget.url, 'pdf'),
                ),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return BoardMediaError(
            url: widget.url,
            error: snapshot.error.toString(),
            onRetry: () => setState(
              () => _file = BoardMediaCache.getFile(widget.url, 'pdf'),
            ),
          );
        }
        final isArabic =
            Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(isArabic ? 'جارٍ حفظ PDF على الجهاز...' : 'Saving PDF to this device...'),
            ],
          ),
        );
      },
    );
  }
}

class CachedBoardImage extends StatefulWidget {
  const CachedBoardImage({required this.url, super.key});
  final String url;

  @override
  State<CachedBoardImage> createState() => _CachedBoardImageState();
}

class _CachedBoardImageState extends State<CachedBoardImage> {
  late Future<File> _file;

  @override
  void initState() {
    super.initState();
    _file = BoardMediaCache.getFile(widget.url, 'image');
  }

  @override
  void didUpdateWidget(covariant CachedBoardImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _file = BoardMediaCache.getFile(widget.url, 'image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: _file,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.file(
            snapshot.data!,
            fit: BoxFit.contain,
            errorBuilder: (_, error, _) => BoardMediaError(
              url: widget.url,
              error: error.toString(),
            ),
          );
        }
        if (snapshot.hasError) {
          return BoardMediaError(
            url: widget.url,
            error: snapshot.error.toString(),
            onRetry: () => setState(
              () => _file = BoardMediaCache.getFile(widget.url, 'image'),
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
