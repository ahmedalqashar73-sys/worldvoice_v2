import 'dart:async';
import 'dart:io';

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
      return _ChatAudio(
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

class _ChatAudio extends StatefulWidget {
  const _ChatAudio({required this.url, required this.cacheScope, super.key});
  final String url;
  final String cacheScope;

  @override
  State<_ChatAudio> createState() => _ChatAudioState();
}

class _ChatAudioState extends State<_ChatAudio> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSub;
  bool _loading = false;
  bool _ready = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _playerSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _playing = state.playing &&
            state.processingState != ProcessingState.completed;
      });
    });
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
        final file = await BoardMediaCache.getFile(
          widget.url, 'audio', cacheScope: widget.cacheScope,
        );
        await _player.setFilePath(file.path);
        _ready = true;
      }
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      if (mounted) unawaited(_player.play());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open voice message.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    unawaited(_playerSub?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 225,
    child: Row(children: [
      IconButton(
        tooltip: _playing ? 'Pause voice' : 'Play voice',
        onPressed: _loading ? null : _toggle,
        icon: _loading
            ? const SizedBox.square(dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(_playing
                ? Icons.pause_circle_rounded : Icons.play_circle_rounded),
      ),
      const Expanded(child: Text('Voice message')),
    ]),
  );
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
