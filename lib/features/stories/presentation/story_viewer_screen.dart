import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/story_service.dart';
import 'story_interaction_sheet.dart';
import '../../chat/presentation/worldvoice_share_to_chat_sheet.dart';

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
  bool _closing = false;
  bool _interacting = false;
  int _loadEpoch = 0;
  bool _advanceQueued = false;
  bool _liked = false;
  int _likeCount = 0;
  int _commentCount = 0;
  bool _allowReplies = true;
  bool _likeBusy = false;

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
    final epoch = ++_loadEpoch;
    _advanceQueued = false;
    _timer?.cancel();
    final oldVideo = _video;
    if (oldVideo != null) {
      oldVideo.removeListener(_videoListener);
      await oldVideo.dispose();
    }
    _video = null;
    if (!mounted || _closing || epoch != _loadEpoch) return;
    setState(() => _mediaLoading = true);

    final story = _story;
    unawaited(_loadInteractions(story.id));
    unawaited(widget.service.recordView(story.id).catchError((_) {}));

    if (story.isVideo) {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(story.mediaUrl),
      );
      _video = controller;
      try {
        await controller.initialize();
        if (!mounted || _closing || epoch != _loadEpoch || _video != controller) return;
        await controller.setLooping(false);
        controller.addListener(_videoListener);
        await controller.play();
        setState(() => _mediaLoading = false);
      } catch (_) {
        if (!mounted || _closing || epoch != _loadEpoch) return;
        setState(() => _mediaLoading = false);
      }
      return;
    }

    if (mounted && !_closing && epoch == _loadEpoch) {
      setState(() => _mediaLoading = false);
    }
    final duration = Duration(
      milliseconds: story.durationMs.clamp(2500, 12000),
    );
    if (mounted && !_closing && epoch == _loadEpoch) {
      _timer = Timer(duration, _next);
    }
  }

  void _videoListener() {
    final controller = _video;
    if (controller == null || _interacting ||
        !controller.value.isInitialized ||
        controller.value.isPlaying) {
      return;
    }
    if (controller.value.position >=
        controller.value.duration - const Duration(milliseconds: 250) &&
        !_advanceQueued) {
      _advanceQueued = true;
      // Do not change Navigator while VideoPlayer listeners are notifying.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_closing && _video == controller) _next();
      });
    }
  }

  Future<void> _loadInteractions(String id) async {
    try {
      final data = await widget.service.fetchStoryInteractions(id);
      if (!mounted || _closing || _story.id != id) return;
      setState(() {
        _liked = data['liked'] == true;
        _likeCount = (data['likesCount'] as num?)?.toInt() ?? 0;
        _commentCount = (data['commentsCount'] as num?)?.toInt() ?? 0;
        _allowReplies = data['allowReplies'] != false;
      });
    } catch (_) {
      // Retry from the activity sheet without blocking Story playback.
    }
  }

  Future<void> _toggleLike() async {
    if (_isOwner || _likeBusy || _closing) return;
    setState(() => _likeBusy = true);
    try {
      await widget.service.setStoryLiked(_story.id, liked: !_liked);
      await _loadInteractions(_story.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _likeBusy = false);
    }
  }

  Future<void> _replyToStory(StoryItem story) async {
    if (_closing || _interacting || widget.onReply == null) return;
    _interacting = true;
    _timer?.cancel();
    await _video?.pause();
    if (!mounted || _closing) return;
    try {
      final status = await widget.service.fetchStoryInteractions(story.id);
      if (status['allowReplies'] != true) {
        throw StateError(ar
            ? 'صاحب الستوري أوقف الردود على الستوري.'
            : 'The Story owner has disabled replies.');
      }
      if (mounted && !_closing) await widget.onReply!(story);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
      }
    } finally {
      _interacting = false;
      if (mounted && !_closing && _story.id == story.id) {
        if (_video?.value.isInitialized == true) {
          await _video?.play();
        } else {
          _timer = Timer(
              Duration(milliseconds: story.durationMs.clamp(2500, 12000)), _next);
        }
      }
    }
  }

  Future<void> _showInteractions() async {
    if (_closing || _interacting) return;
    _interacting = true;
    _timer?.cancel();
    await _video?.pause();
    if (!mounted || _closing) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => StoryInteractionSheet(
        story: _story, service: widget.service,
        owner: _isOwner, isArabic: ar),
    );
    if (!mounted || _closing) return;
    _interacting = false;
    unawaited(_loadInteractions(_story.id));
    if (_video?.value.isInitialized == true) {
      await _video?.play();
    } else {
      _timer = Timer(Duration(milliseconds: _story.durationMs.clamp(2500, 12000)), _next);
    }
  }

  Future<void> _showStorySettings() async {
    if (_closing || _interacting) return;
    _interacting = true;
    _timer?.cancel();
    await _video?.pause();
    if (!mounted || _closing) return;
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, useSafeArea: true,
      showDragHandle: true,
      builder: (_) => StorySettingsSheet(service: widget.service,
          isArabic: ar),
    );
    if (!mounted || _closing) return;
    _interacting = false;
    unawaited(_loadInteractions(_story.id));
    if (_video?.value.isInitialized == true) {
      await _video?.play();
    } else {
      _timer = Timer(Duration(milliseconds: _story.durationMs.clamp(2500, 12000)), _next);
    }
  }

  void _exitStory() {
    if (!mounted || _closing) return;
    _closing = true;
    _timer?.cancel();
    ++_loadEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  void _next() {
    if (!mounted || _closing || _interacting) return;
    _timer?.cancel();
    if (_index >= widget.stories.length - 1) {
      _exitStory();
      return;
    }
    setState(() => _index += 1);
    unawaited(_showCurrent());
  }

  void _previous() {
    if (_closing || _index <= 0) return;
    _timer?.cancel();
    setState(() => _index -= 1);
    unawaited(_showCurrent());
  }

  Future<void> _deleteCurrent() async {
    final story = _story;
    try {
      await widget.service.deleteStory(story.id);
      widget.onChanged?.call();
      if (!mounted) return;
      _exitStory();
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
    _closing = true;
    ++_loadEpoch;
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
                        } else if (value == 'activity') {
                          unawaited(_showInteractions());
                        } else if (value == 'privacy') {
                          unawaited(_showStorySettings());
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'activity',
                          child: Text(ar ? 'الإعجابات والتعليقات' : 'Likes & comments',
                              style: const TextStyle(color: Colors.white)),
                        ),
                        PopupMenuItem(
                          value: 'privacy',
                          child: Text(ar ? 'خصوصية الاستوري' : 'Story privacy',
                              style: const TextStyle(color: Colors.white)),
                        ),
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
                    tooltip: ar ? 'مشاركة الستوري' : 'Share story in chat',
                    onPressed: () => WorldVoiceShareToChatSheet.show(
                      context,
                      text: '🌸 WorldVoice Story\n'
                          '${story.ownerName}\n'
                          'worldvoice://story/${story.id}',
                      title: ar ? 'مشاركة الستوري إلى...' : 'Share story to...',
                    ),
                    icon: const Icon(Icons.ios_share_rounded,
                      color: Colors.white),
                  ),
                  IconButton(
                    onPressed: _exitStory,
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
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: SafeArea(
                top: false,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .60),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(children: [
                      if (!_isOwner) ...[
                        IconButton(
                          tooltip: ar ? 'إعجاب' : 'Like Story',
                          onPressed: _likeBusy ? null : _toggleLike,
                          icon: Icon(_liked ? Icons.favorite : Icons.favorite_border,
                              color: _liked ? Colors.redAccent : Colors.white),
                        ),
                        Text('$_likeCount',
                          style: const TextStyle(color: Colors.white)),
                      ],
                      IconButton(
                        tooltip: ar ? 'التعليقات' : 'Comments',
                        onPressed: _showInteractions,
                        icon: const Icon(Icons.mode_comment_outlined,
                            color: Colors.white),
                      ),
                      Text('$_commentCount',
                        style: const TextStyle(color: Colors.white)),
                      if (!_isOwner && _allowReplies && widget.onReply != null)
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _replyToStory(story),
                            icon: const Icon(Icons.reply_rounded,
                                color: Colors.white),
                            label: Text(ar ? 'رد في الدردشة' : 'Reply in chat',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white)),
                          ),
                        )
                      else
                        const Spacer(),
                      if (_isOwner)
                        IconButton(
                          tooltip: ar ? 'إعدادات الخصوصية' : 'Privacy settings',
                          onPressed: _showStorySettings,
                          icon: const Icon(Icons.shield_outlined,
                              color: Colors.white),
                        ),
                    ]),
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
