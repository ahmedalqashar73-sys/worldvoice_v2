import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:video_player/video_player.dart';

import '../services/room_device_media_store.dart';

/// Opens personal files directly from the current phone; this route does not
/// upload the document or its contents to WorldVoice.
class RoomDeviceMediaViewer {
  RoomDeviceMediaViewer._();

  static Future<void> open(
    BuildContext context,
    RoomDeviceMedia media,
  ) async {
    final page = switch (media.type) {
      'image' => _LocalImagePage(path: media.path, title: media.name),
      'video' => _LocalVideoPage(path: media.path, title: media.name),
      _ => _LocalPdfPage(path: media.path, title: media.name),
    };
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  static Future<void> openOlderPdf(
    BuildContext context, {
    required String url,
    required String name,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _OlderPdfPage(url: url, title: name),
      ),
    );
  }
}

class _LocalImagePage extends StatelessWidget {
  const _LocalImagePage({required this.path, required this.title});

  final String path;
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        backgroundColor: Colors.black,
        body: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 6,
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Text(
                'Image cannot be opened on this device.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      );
}

class _LocalPdfPage extends StatelessWidget {
  const _LocalPdfPage({required this.path, required this.title});

  final String path;
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: PdfViewer.file(path),
      );
}

class _OlderPdfPage extends StatefulWidget {
  const _OlderPdfPage({required this.url, required this.title});

  final String url;
  final String title;

  @override
  State<_OlderPdfPage> createState() => _OlderPdfPageState();
}

class _OlderPdfPageState extends State<_OlderPdfPage> {
  final RoomDeviceMediaStore _store = RoomDeviceMediaStore();
  late Future<File> _download;

  @override
  void initState() {
    super.initState();
    _download = _store.cacheOlderPdf(widget.url);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: FutureBuilder<File>(
          future: _download,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 50),
                      const SizedBox(height: 12),
                      Text(
                        'The old PDF could not be downloaded to this phone.\n'
                        'It may have been removed or blocked. '
                        'Ask the owner to select the original PDF again.\n\n'
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => setState(() {
                          _download = _store.cacheOlderPdf(widget.url);
                        }),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry download'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Downloading PDF to this device...'),
                  ],
                ),
              );
            }
            return PdfViewer.file(snapshot.data!.path);
          },
        ),
      );
}

class _LocalVideoPage extends StatefulWidget {
  const _LocalVideoPage({required this.path, required this.title});

  final String path;
  final String title;

  @override
  State<_LocalVideoPage> createState() => _LocalVideoPageState();
}

class _LocalVideoPageState extends State<_LocalVideoPage> {
  late VideoPlayerController _player;
  late Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _player = VideoPlayerController.file(
      File(widget.path),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _player.addListener(_changed);
    _ready = _player.initialize().timeout(const Duration(seconds: 25));
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _player.removeListener(_changed);
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        backgroundColor: Colors.black,
        body: FutureBuilder<void>(
          future: _ready,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Could not play this video:\n${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              );
            }
            if (snapshot.connectionState != ConnectionState.done ||
                !_player.value.isInitialized) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _player.value.aspectRatio > 0
                        ? _player.value.aspectRatio
                        : 16 / 9,
                    child: VideoPlayer(_player),
                  ),
                  VideoProgressIndicator(
                    _player,
                    allowScrubbing: true,
                    padding: const EdgeInsets.all(12),
                  ),
                  IconButton.filledTonal(
                    iconSize: 36,
                    onPressed: () =>
                        _player.value.isPlaying ? _player.pause() : _player.play(),
                    icon: Icon(
                      _player.value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}
