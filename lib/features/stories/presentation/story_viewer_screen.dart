import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/story_service.dart';

class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({
    required this.stories,
    required this.service,
    required this.isArabic,
    this.onReply,
    this.onChanged,
    super.key,
  });

  final List<StoryItem> stories;
  final StoryService service;
  final bool isArabic;
  final Future<void> Function(StoryItem story)? onReply;
  final VoidCallback? onChanged;

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  int _index = 0;
  Timer? _timer;
  VideoPlayerController? _video;
  bool _mediaLoading = true;

  bool get ar => widget.isArabic;
  StoryItem get _story => widget.stories[_index];
  bool get _isOwner =>
      FirebaseAuth.instance.currentUser?.uid == _story.ownerId;

  @override
  void initState() {
    super.initState();
    unawaited(_showCurrent());
  }

  Future<void> _showCurrent() async {
    _timer?.cancel();
    final oldVideo = _video;
    if (oldVideo != null) {
      oldVideo.removeListener(_videoListener);
      await oldVideo.dispose();
    }
    _video = null;
    if (!mounted) return;
    setState(() => _mediaLoading = true);

    final story = _story;
    unawaited(widget.service.recordView(story.id).catchError((_) {}));

    if (story.isVideo) {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(story.mediaUrl),
      );
      _video = controller;
      try {
        await controller.initialize();
        if (!mounted || _video != controller) return;
        await controller.setLooping(false);
        controller.addListener(_videoListener);
        await controller.play();
        setState(() => _mediaLoading = false);
      } catch (_) {
        if (!mounted) return;
        setState(() => _mediaLoading = false);
      }
      return;
    }

    if (mounted) setState(() => _mediaLoading = false);
    final duration = Duration(
      milliseconds: story.durationMs.clamp(2500, 12000),
    );
    _timer = Timer(duration, _next);
  }

  void _videoListener() {
    final controller = _video;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isPlaying) {
      return;
    }
    if (controller.value.position >=
        controller.value.duration - const Duration(milliseconds: 250)) {
      _next();
    }
  }

  void _next() {
    if (!mounted) return;
    if (_index >= widget.stories.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index += 1);
    unawaited(_showCurrent());
  }

  void _previous() {
    if (_index <= 0) return;
    setState(() => _index -= 1);
    unawaited(_showCurrent());
  }

  Future<void> _deleteCurrent() async {
    final story = _story;
    try {
      await widget.service.deleteStory(story.id);
      widget.onChanged?.call();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    final video = _video;
    if (video != null) {
      video.removeListener(_videoListener);
      unawaited(video.dispose());
    }
    super.dispose();
  }

  String _ageText() {
    final diff = DateTime.now().millisecondsSinceEpoch - _story.createdAtMs;
    final minutes = (diff / 60000).floor().clamp(0, 59);
    final hours = (diff / 3600000).floor();
    if (hours > 0) {
      return ar ? 'منذ $hours س' : '${hours}h';
    }
    return ar ? 'منذ $minutes د' : '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final story = _story;
    final photo = story.ownerPhotoUrl.trim();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: story.isVideo
                  ? (_video?.value.isInitialized == true
                      ? FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: _video!.value.size.width,
                            height: _video!.value.size.height,
                            child: VideoPlayer(_video!),
                          ),
                        )
                      : const ColoredBox(color: Colors.black))
                  : Image.network(
                      story.mediaUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 48,
                        ),
                      ),
                    ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: .62),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: .55),
                      ],
                      stops: const [0, .20, .72, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              top: 8,
              child: Row(
                children: [
                  for (var i = 0; i < widget.stories.length; i++) ...[
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: i <= _index
                              ? Colors.white
                              : Colors.white.withValues(alpha: .30),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    if (i != widget.stories.length - 1)
                      const SizedBox(width: 3),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 8,
              top: 22,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage:
                        photo.isEmpty ? null : NetworkImage(photo),
                    child: photo.isEmpty
                        ? const Icon(Icons.person_rounded)
                        : null,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            story.ownerName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          _ageText(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (story.isCloseFriends)
                    Container(
                      margin: const EdgeInsetsDirectional.only(end: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13A06E),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Close Friends',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_isOwner)
                    PopupMenuButton<String>(
                      color: const Color(0xFF181818),
                      iconColor: Colors.white,
                      onSelected: (value) {
                        if (value == 'delete') {
                          unawaited(_deleteCurrent());
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            ar ? 'حذف الستوري' : 'Delete story',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              top: 82,
              bottom: 78,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _previous,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _next,
                    ),
                  ),
                ],
              ),
            ),
            if (!_isOwner && widget.onReply != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: SafeArea(
                  top: false,
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: .52),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: () => widget.onReply!(story),
                    icon: const Icon(Icons.reply_rounded),
                    label: Text(
                      ar ? 'رد برسالة' : 'Reply in message',
                    ),
                  ),
                ),
              ),
            if (_mediaLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
