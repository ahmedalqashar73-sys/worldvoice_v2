import 'dart:async';
import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:video_player/video_player.dart';

import '../../rooms/services/board_media_cache.dart';

/// Chat attachments are kept in app-private, account-scoped local storage.
/// A remote URL is retained for delivery to the other participant.
class ChatMediaBubble extends StatefulWidget {
  const ChatMediaBubble({
    required this.type,
    required this.url,
    required this.cacheScope,
    this.fileName,
    super.key,
  });

  final String type;
  final String url;
  final String cacheScope;
  final String? fileName;

  @override
  State<ChatMediaBubble> createState() => _ChatMediaBubbleState();
}

class _ChatMediaBubbleState extends State<ChatMediaBubble> {
  Future<File>? _imageFile;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'image') {
      _imageFile = BoardMediaCache.getFile(
        widget.url, 'image', cacheScope: widget.cacheScope,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ChatMediaBubble old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url || old.type != widget.type ||
        old.cacheScope != widget.cacheScope) {
      _imageFile = widget.type == 'image'
          ? BoardMediaCache.getFile(
              widget.url, 'image', cacheScope: widget.cacheScope,
            )
          : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == 'image') {
      return FutureBuilder<File>(
        future: _imageFile,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                snapshot.data!, width: 260, height: 220,
                fit: BoxFit.cover,
              ),
            );
          }
          if (snapshot.hasError) {
            return const SizedBox(
              width: 220, height: 120,
              child: Center(child: Icon(Icons.broken_image_outlined)),
            );
          }
          return const SizedBox(
            width: 220, height: 140,
            child: Center(child: CircularProgressIndicator()),
          );
        },
      );
    }
    if (widget.type == 'video') {
      return _ChatVideo(
        key: ValueKey(widget.url),
        url: widget.url,
        cacheScope: widget.cacheScope,
      );
    }
    if (widget.type == 'audio') {
      return WorldVoiceVoiceMessageBubble(
        key: ValueKey(widget.url),
        url: widget.url,
        cacheScope: widget.cacheScope,
      );
    }
    return _ChatPdf(
      url: widget.url,
      fileName: widget.fileName ?? 'Document.pdf',
      cacheScope: widget.cacheScope,
    );
  }
}

/// Shared playback bubble for the encrypted device-only conversation and
/// the legacy delivered-media thread. Never expose .m4a filenames as messages.
/// Loading remote audio uses the same account-scoped private media cache.
class WorldVoiceVoiceMessageBubble extends StatefulWidget {
  const WorldVoiceVoiceMessageBubble({
    this.url = '',
    this.localPath = '',
    this.cacheScope = '',
    super.key,
  });

  final String url;
  final String localPath;
  final String cacheScope;

  @override
  State<WorldVoiceVoiceMessageBubble> createState() =>
      _WorldVoiceVoiceMessageBubbleState();
}

class _WorldVoiceVoiceMessageBubbleState
    extends State<WorldVoiceVoiceMessageBubble> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  static const _bars = <double>[
    0.26, 0.55, 0.8, 0.36, 0.64, 0.95, 0.6, 0.3,
    0.72, 0.98, 0.44, 0.7, 0.47, 0.85, 0.33, 0.65,
    0.9, 0.52, 0.3, 0.76, 0.48, 0.9, 0.62, 0.38,
  ];
  bool _loading = false;
  bool _ready = false;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    _playerSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _playing = state.playing &&
            state.processingState != ProcessingState.completed;
        if (state.processingState == ProcessingState.completed) {
          _position = _duration;
        }
      });
    });
    _positionSub = _player.positionStream.listen((position) {
      if (mounted) setState(() => _position = position);
    });
    _durationSub = _player.durationStream.listen((duration) {
      if (duration != null && mounted) setState(() => _duration = duration);
    });
  }

  @override
  void didUpdateWidget(covariant WorldVoiceVoiceMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.localPath != widget.localPath ||
        oldWidget.cacheScope != widget.cacheScope) {
      _ready = false;
      _playing = false;
      _duration = Duration.zero;
      _position = Duration.zero;
      unawaited(_player.stop());
    }
  }

  Future<void> _toggle() async {
    if (_loading) return;
    if (_playing) {
      await _player.pause();
      return;
    }
    try {
      if (!_ready) {
        setState(() => _loading = true);
        final path = widget.localPath.trim().isNotEmpty
            ? widget.localPath.trim()
            : (await BoardMediaCache.getFile(
                widget.url, 'audio', cacheScope: widget.cacheScope,
              )).path;
        if (!await File(path).exists()) {
          throw StateError('Voice attachment is unavailable on this device.');
        }
        await _player.setFilePath(path);
        _duration = _player.duration ?? Duration.zero;
        _ready = true;
      }
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      unawaited(_player.play());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'تعذر فتح الرسالة الصوتية. أعد المحاولة.'
                : 'Could not play voice message. Try again.',
          )),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _seek(double ratio) async {
    if (!_ready || _duration.inMilliseconds <= 0) return;
    await _player.seek(Duration(
      milliseconds: (_duration.inMilliseconds * ratio.clamp(0.0, 1.0))
          .round(),
    ));
  }

  String _clock(Duration d) {
    final value = d.inSeconds.clamp(0, 359999);
    return '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    unawaited(_playerSub?.cancel());
    unawaited(_positionSub?.cancel());
    unawaited(_durationSub?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final duration = _duration.inMilliseconds;
    final ratio = duration <= 0
        ? 0.0
        : (_position.inMilliseconds / duration).clamp(0.0, 1.0);
    final shown = _playing ? _position : _duration;
    return Semantics(
      label: ar ? 'رسالة صوتية' : 'Voice message',
      child: SizedBox(
        width: 242,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filledTonal(
              key: const ValueKey('worldvoice-voice-play'),
              tooltip: _playing
                  ? (ar ? 'إيقاف مؤقت' : 'Pause voice')
                  : (ar ? 'تشغيل الرسالة الصوتية' : 'Play voice'),
              onPressed: _loading ? null : _toggle,
              icon: _loading
                  ? const SizedBox.square(
                      dimension: 19,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ar ? 'رسالة صوتية' : 'Voice message',
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LayoutBuilder(builder: (context, constraints) {
                    return GestureDetector(
                      key: const ValueKey('worldvoice-voice-waveform'),
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) => unawaited(_seek(
                        details.localPosition.dx /
                            constraints.maxWidth,
                      )),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var i = 0; i < _bars.length; i++)
                            Container(
                              width: 2.8,
                              height: 6 + _bars[i] * 18,
                              decoration: BoxDecoration(
                                color: i / _bars.length <= ratio
                                    ? const Color(0xFF61E1A0)
                                    : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: .45),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _clock(shown),
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontSize: 11,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatPdf extends StatefulWidget {
  const _ChatPdf({
    required this.url,
    required this.fileName,
    required this.cacheScope,
  });
  final String url;
  final String fileName;
  final String cacheScope;

  @override
  State<_ChatPdf> createState() => _ChatPdfState();
}

class _ChatPdfState extends State<_ChatPdf> {
  bool _busy = false;

  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await BoardMediaCache.getFile(
        widget.url, 'pdf', cacheScope: widget.cacheScope,
      );
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(widget.fileName)),
          body: PdfViewer.file(file.path),
        ),
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open PDF attachment.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 240,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _busy
          ? const CircularProgressIndicator()
          : const Icon(Icons.picture_as_pdf_outlined, size: 32),
      title: Text(widget.fileName, maxLines: 2,
        overflow: TextOverflow.ellipsis),
      onTap: _busy ? null : _open,
    ),
  );
}

class _ChatVideo extends StatefulWidget {
  const _ChatVideo({
    required this.url, required this.cacheScope, super.key,
  });
  final String url;
  final String cacheScope;

  @override
  State<_ChatVideo> createState() => _ChatVideoState();
}

class _ChatVideoState extends State<_ChatVideo> {
  VideoPlayerController? _controller;
  bool _loading = false;

  Future<void> _loadAndPlay() async {
    if (_loading) return;
    final current = _controller;
    if (current != null && current.value.isInitialized) {
      if (current.value.isPlaying) {
        await current.pause();
      } else {
        await current.play();
      }
      if (mounted) setState(() {});
      return;
    }
    setState(() => _loading = true);
    VideoPlayerController? pending;
    try {
      final file = await BoardMediaCache.getFile(
        widget.url, 'video', cacheScope: widget.cacheScope,
      );
      if (!mounted) return;
      pending = VideoPlayerController.file(file);
      await pending.initialize();
      if (!mounted) {
        await pending.dispose();
        return;
      }
      _controller = pending;
      await pending.play();
    } catch (_) {
      await pending?.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open video attachment.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller?.value.isInitialized == true;
    return SizedBox(
      width: 260,
      child: AspectRatio(
        aspectRatio: ready && controller!.value.aspectRatio > 0
            ? controller.value.aspectRatio : 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.black,
              child: ready
                  ? FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: controller!.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.videocam_rounded,
                        size: 44, color: Colors.white70),
                    ),
            ),
            Center(
              child: IconButton.filled(
                onPressed: _loading ? null : _loadAndPlay,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(ready && controller!.value.isPlaying
                        ? Icons.pause_rounded : Icons.play_arrow_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
