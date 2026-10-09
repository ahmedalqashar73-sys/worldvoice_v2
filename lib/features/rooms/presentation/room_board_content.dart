import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:video_player/video_player.dart';

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
  const BoardVideo({required this.url, super.key});
  final String url;
  @override
  State<BoardVideo> createState() => _BoardVideoState();
}
class _BoardVideoState extends State<BoardVideo> {
  late VideoPlayerController _player;
  bool _disposed = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _player = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initialize();
  }
  Future<void> _initialize() async {
    File? cached;
    try {
      cached = await BoardMediaCache.cachedFileIfPresent(widget.url, 'video');
    } catch (_) {
      // A cache miss or an unavailable storage directory is not fatal.
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
        // Stream immediately, then keep a bounded local copy for the next
        // opening. Never block the video player on a full-file download.
        unawaited(
          BoardMediaCache.getFile(widget.url, 'video')
              .then((_) {})
              .catchError((Object _) {}),
        );
      }
    } catch (error) {
      // Retain the old Cloudinary-compatible streaming fallback.
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
    if (mounted) setState(() {});
  }
  @override
  void dispose() { _disposed = true; _player.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    if (_error != null) return BoardMediaError(url: widget.url, error: _error!);
    return ValueListenableBuilder<VideoPlayerValue>(valueListenable: _player,
      builder: (context, value, _) {
        if (value.hasError) return BoardMediaError(url: widget.url, error: value.errorDescription ?? 'Video playback failed');
        if (!value.isInitialized) return const Center(child: CircularProgressIndicator());
        return LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxHeight < 80) {
            return Center(child: IconButton(
              onPressed: () => value.isPlaying ? _player.pause() : _player.play(),
              icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow)));
          }
          return Column(children: [
          Expanded(child: Center(child: AspectRatio(aspectRatio: value.aspectRatio, child: VideoPlayer(_player)))),
          SizedBox(height: 40, child: Row(children: [
            IconButton(tooltip: ar ? 'تشغيل / إيقاف' : 'Play / pause',
              onPressed: () async {
                try {
                  if (value.isPlaying) { await _player.pause(); }
                  else { await _player.play(); }
                } catch (_) { if (mounted) setState(() => _error = 'Video playback failed'); }
              }, icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow)),
            Expanded(child: VideoProgressIndicator(_player, allowScrubbing: true)),
            IconButton(tooltip: ar ? 'صوت الفيديو' : 'Video sound',
              onPressed: () => _player.setVolume(value.volume == 0 ? 1 : 0),
              icon: Icon(value.volume == 0 ? Icons.volume_off : Icons.volume_up)),
          ])),
        ]);
        });
      });
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
