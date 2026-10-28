import 'dart:async';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/story_service.dart';
import '../services/story_filter_presets.dart';
import 'story_interaction_sheet.dart';
import '../../live/presentation/live_screen.dart';
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

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(vsync: this);
  int _index = 0;
  Timer? _timer;
  VideoPlayerController? _video;
  bool _mediaLoading = true;
  bool _mediaReady = false;
  bool _closing = false;
  bool _interacting = false;
  int _loadEpoch = 0;
  bool _advanceQueued = false;
  bool _liked = false;
  int? _viewCount;
  List<Map> _viewers = [];
  bool _allowReplies = true;
  bool _likeBusy = false;

  bool get ar => widget.isArabic;
  StoryItem get _story => widget.stories[_index];
  bool get _isOwner => FirebaseAuth.instance.currentUser?.uid == _story.ownerId;

  @override
  void initState() {
    super.initState();
    unawaited(_showCurrent());
  }

  Future<void> _showCurrent() async {
    final epoch = ++_loadEpoch;
    _advanceQueued = false;
    _mediaReady = false;
    _progress.value = 0;
    _viewCount = null;
    _viewers = [];
    _liked = false;
    _allowReplies = false;
    _timer?.cancel();
    _progress.stop();
    final oldVideo = _video;
    _video = null;
    setState(() => _mediaLoading = true);
    if (oldVideo != null) {
      oldVideo.removeListener(_videoListener);
      await oldVideo.dispose();
    }
    if (!mounted || _closing || epoch != _loadEpoch) return;

    final story = _story;
    unawaited(_loadInteractions(story.id));

    if (story.isLiveShare) {
      setState(() {
        _mediaLoading = false;
        _mediaReady = true;
      });
      unawaited(widget.service.recordView(story.id).catchError((_) {}));
      _resumePhoto();
      return;
    }
    if (story.isVideo) {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(story.mediaUrl),
      );
      _video = controller;
      try {
        await controller.initialize();
        if (!mounted ||
            _closing ||
            epoch != _loadEpoch ||
            _video != controller) {
          return;
        }
        await controller.setLooping(false);
        controller.addListener(_videoListener);
        if (!_interacting) await controller.play();
        if (!mounted || _closing || epoch != _loadEpoch) return;
        setState(() {
          _mediaLoading = false;
          _mediaReady = true;
        });
        unawaited(widget.service.recordView(story.id).catchError((_) {}));
      } catch (_) {
        if (!mounted || _closing || epoch != _loadEpoch) return;
        setState(() => _mediaLoading = false);
      }
      return;
    }

    try {
      // Count a view and start its clock only after the image is available.
      Object? imageError;
      await precacheImage(
        NetworkImage(story.mediaUrl),
        context,
        onError: (Object error, StackTrace? stack) {
          imageError = error;
        },
      );
      if (imageError != null) throw imageError!;
      if (!mounted || _closing || epoch != _loadEpoch) return;
      setState(() {
        _mediaLoading = false;
        _mediaReady = true;
      });
      unawaited(widget.service.recordView(story.id).catchError((_) {}));
      if (!_interacting) _resumePhoto();
    } catch (_) {
      if (mounted && epoch == _loadEpoch) setState(() => _mediaLoading = false);
    }
  }

  void _resumePhoto() {
    if (!_mediaReady || _story.isVideo || _interacting || _closing) return;
    final remaining =
        (_story.durationMs.clamp(2500, 12000) * (1 - _progress.value)).round();
    final duration = Duration(milliseconds: remaining.clamp(1, 12000));
    _progress.animateTo(1, duration: duration, curve: Curves.linear);
    _timer?.cancel();
    _timer = Timer(duration, _next);
  }

  void _hold() {
    if (_interacting || _closing) return;
    _interacting = true;
    _timer?.cancel();
    _progress.stop();
    unawaited(_video?.pause());
  }

  void _releaseHold() {
    if (!_interacting || _closing) return;
    _interacting = false;
    if (_mediaLoading) return;
    if (_story.isVideo) {
      unawaited(_video?.play());
    } else {
      _resumePhoto();
    }
  }

  Future<void> _shareStory() async {
    if (_interacting || _closing) return;
    _hold();
    final story = _story;
    try {
      await WorldVoiceShareToChatSheet.show(
        context,
        text:
            '🌸 WorldVoice Story\n${story.ownerName}\nworldvoice://story/${story.id}',
        title: ar ? 'مشاركة الستوري إلى...' : 'Share story to...',
      );
    } finally {
      if (mounted && !_closing) _releaseHold();
    }
  }

  void _videoListener() {
    final controller = _video;
    if (controller != null &&
        controller.value.isInitialized &&
        controller.value.duration.inMilliseconds > 0) {
      _progress.value =
          (controller.value.position.inMilliseconds /
                  controller.value.duration.inMilliseconds)
              .clamp(0.0, 1.0);
    }
    if (controller == null ||
        _interacting ||
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
        _viewCount = (data['viewsCount'] as num?)?.toInt();
        _viewers =
            (data['viewers'] as List?)?.whereType<Map>().take(3).toList() ?? [];
        _allowReplies = data['allowReplies'] != false;
      });
    } catch (_) {
      // Retry from the activity sheet without blocking Story playback.
    }
  }

  Future<void> _toggleLike() async {
    if (_isOwner || _likeBusy || _closing) return;
    final id = _story.id;
    final liked = !_liked;
    setState(() => _likeBusy = true);
    try {
      await widget.service.setStoryLiked(id, liked: liked);
      await _loadInteractions(id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _likeBusy = false);
    }
  }

  Future<void> _replyToStory(StoryItem story) async {
    if (_closing || _interacting || widget.onReply == null) return;
    _interacting = true;
    _timer?.cancel();
    _progress.stop();
    await _video?.pause();
    if (!mounted || _closing) return;
    try {
      final status = await widget.service.fetchStoryInteractions(story.id);
      if (status['allowReplies'] != true) {
        throw StateError(
          ar
              ? 'صاحب الستوري أوقف الردود على الستوري.'
              : 'The Story owner has disabled replies.',
        );
      }
      if (mounted && !_closing) await widget.onReply!(story);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    } finally {
      _interacting = false;
      if (mounted && !_closing && _story.id == story.id) {
        if (_video?.value.isInitialized == true) {
          await _video?.play();
        } else {
          _resumePhoto();
        }
      }
    }
  }

  Future<void> _showInteractions() async {
    if (_closing || _interacting) return;
    _interacting = true;
    _timer?.cancel();
    _progress.stop();
    await _video?.pause();
    if (!mounted || _closing) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => StoryInteractionSheet(
        story: _story,
        service: widget.service,
        owner: _isOwner,
        isArabic: ar,
      ),
    );
    if (!mounted || _closing) return;
    _interacting = false;
    unawaited(_loadInteractions(_story.id));
    if (_video?.value.isInitialized == true) {
      await _video?.play();
    } else {
      _resumePhoto();
    }
  }

  Future<void> _showStorySettings() async {
    if (_closing || _interacting) return;
    _interacting = true;
    _timer?.cancel();
    _progress.stop();
    await _video?.pause();
    if (!mounted || _closing) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => StorySettingsSheet(service: widget.service, isArabic: ar),
    );
    if (!mounted || _closing) return;
    _interacting = false;
    unawaited(_loadInteractions(_story.id));
    if (_video?.value.isInitialized == true) {
      await _video?.play();
    } else {
      _resumePhoto();
    }
  }

  void _exitStory() {
    if (!mounted || _closing) return;
    _closing = true;
    _timer?.cancel();
    _progress.stop();
    ++_loadEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  void _next() {
    if (!mounted || _closing || _interacting) return;
    _timer?.cancel();
    _progress.stop();
    if (_index >= widget.stories.length - 1) {
      _exitStory();
      return;
    }
    setState(() => _index += 1);
    unawaited(_showCurrent());
  }

  void _previous() {
    if (_closing || _interacting || _index <= 0) return;
    _timer?.cancel();
    _progress.stop();
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
    _progress.stop();
    final video = _video;
    if (video != null) {
      video.removeListener(_videoListener);
      unawaited(video.dispose());
    }
    _progress.dispose();
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
            if (!story.isVideo)
              Positioned.fill(
                child: IgnorePointer(
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Opacity(
                      opacity: .35,
                      child: Image.network(
                        story.mediaUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              top: 78,
              bottom: 86,
              child: story.isLiveShare
                  ? Center(
                      child: FilledButton.icon(
                        onPressed: () async {
                          _hold();
                          await Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => WorldVoiceLiveInvitationPage(
                                liveId: story.liveId,
                              ),
                            ),
                          );
                          if (mounted && !_closing) _releaseHold();
                        },
                        icon: const Icon(Icons.videocam),
                        label: Text(ar ? 'انضم للبث المباشر' : 'Join Live'),
                      ),
                    )
                  : story.isVideo
                  ? (_video?.value.isInitialized == true
                        ? FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: _video!.value.size.width,
                              height: _video!.value.size.height,
                              child: ColorFiltered(
                                colorFilter: ColorFilter.matrix(
                                  storyFilterMatrix(
                                    storyFilterFromName(story.filter),
                                  ),
                                ),
                                child: VideoPlayer(_video!),
                              ),
                            ),
                          )
                        : const ColoredBox(color: Colors.black))
                  : Image.network(
                      story.mediaUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
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
                      child: AnimatedBuilder(
                        animation: _progress,
                        builder: (_, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            value: i < _index
                                ? 1
                                : i == _index
                                ? _progress.value
                                : 0,
                            color: Colors.white,
                            backgroundColor: Colors.white30,
                          ),
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
                    backgroundImage: photo.isEmpty ? null : NetworkImage(photo),
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
                      onOpened: _hold,
                      onCanceled: _releaseHold,
                      onSelected: (value) {
                        _releaseHold();
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
                          child: Text(
                            ar ? 'الإعجابات والتعليقات' : 'Likes & comments',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'privacy',
                          child: Text(
                            ar ? 'خصوصية الاستوري' : 'Story privacy',
                            style: const TextStyle(color: Colors.white),
                          ),
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
                    onPressed: _exitStory,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
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
                      onLongPressStart: (_) => _hold(),
                      onLongPressEnd: (_) => _releaseHold(),
                      onVerticalDragEnd: (details) {
                        if (_isOwner && (details.primaryVelocity ?? 0) < -150) {
                          unawaited(_showInteractions());
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _next,
                      onLongPressStart: (_) => _hold(),
                      onLongPressEnd: (_) => _releaseHold(),
                      onVerticalDragEnd: (details) {
                        if (_isOwner && (details.primaryVelocity ?? 0) < -150) {
                          unawaited(_showInteractions());
                        }
                      },
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
                child: Row(
                  children: [
                    if (_isOwner) ...[
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _showInteractions,
                          icon: _viewers.isEmpty
                              ? const Icon(
                                  Icons.people_outline,
                                  color: Colors.white,
                                )
                              : SizedBox(
                                  width: 64,
                                  height: 32,
                                  child: Stack(
                                    children: [
                                      for (var i = 0; i < _viewers.length; i++)
                                        Positioned(
                                          left: i * 16.0,
                                          child: CircleAvatar(
                                            radius: 16,
                                            backgroundImage:
                                                (_viewers[i]['photoUrl'] ?? '')
                                                    .toString()
                                                    .isEmpty
                                                ? null
                                                : NetworkImage(
                                                    _viewers[i]['photoUrl']
                                                        .toString(),
                                                  ),
                                            child:
                                                (_viewers[i]['photoUrl'] ?? '')
                                                    .toString()
                                                    .isEmpty
                                                ? const Icon(
                                                    Icons.person,
                                                    size: 18,
                                                  )
                                                : null,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                          label: Text(
                            _viewCount == null
                                ? (ar ? 'النشاط' : 'Activity')
                                : (ar
                                      ? 'النشاط • $_viewCount مشاهدة'
                                      : 'Activity • $_viewCount views'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _showStorySettings,
                        tooltip: ar ? 'الخصوصية' : 'Privacy',
                        icon: const Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.all(14),
                          ),
                          onPressed: _allowReplies && widget.onReply != null
                              ? () => _replyToStory(story)
                              : null,
                          child: Text(
                            _allowReplies
                                ? (ar ? 'إرسال رسالة' : 'Send message')
                                : (ar ? 'الردود مغلقة' : 'Replies off'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _likeBusy ? null : _toggleLike,
                        tooltip: ar ? 'إعجاب' : 'Like',
                        icon: Icon(
                          _liked ? Icons.favorite : Icons.favorite_border,
                          color: _liked ? Colors.redAccent : Colors.white,
                        ),
                      ),
                      if (_allowReplies)
                        IconButton(
                          onPressed: _showInteractions,
                          tooltip: ar ? 'تعليق خاص' : 'Private comment',
                          icon: const Icon(
                            Icons.mode_comment_outlined,
                            color: Colors.white,
                          ),
                        ),
                    ],
                    IconButton(
                      onPressed: _shareStory,
                      tooltip: ar ? 'مشاركة' : 'Share',
                      icon: const Icon(
                        Icons.send_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ],
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
