import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ChatMediaBubble extends StatelessWidget {
  const ChatMediaBubble({
    required this.type,
    required this.url,
    super.key,
  });

  final String type;
  final String url;

  @override
  Widget build(BuildContext context) {
    if (type == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          url,
          width: 260,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox(
            width: 220,
            height: 120,
            child: Center(child: Icon(Icons.broken_image_outlined)),
          ),
        ),
      );
    }
    return _ChatVideo(url: url);
  }
}

class _ChatVideo extends StatefulWidget {
  const _ChatVideo({required this.url});
  final String url;

  @override
  State<_ChatVideo> createState() => _ChatVideoState();
}

class _ChatVideoState extends State<_ChatVideo> {
  late final VideoPlayerController _controller =
      VideoPlayerController.networkUrl(Uri.parse(widget.url));
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(false);
      if (mounted) setState(() => _ready = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: AspectRatio(
        aspectRatio: _ready && _controller.value.aspectRatio > 0
            ? _controller.value.aspectRatio
            : 16 / 10,
        child: ColoredBox(
          color: Colors.black,
          child: _ready
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                    Center(
                      child: IconButton.filled(
                        onPressed: () {
                          if (_controller.value.isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.play();
                          }
                          setState(() {});
                        },
                        icon: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
        ),
      ),
    );
  }
}
