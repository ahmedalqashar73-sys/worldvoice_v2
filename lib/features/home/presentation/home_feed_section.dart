import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../core/localization/locale_controller.dart';
import '../../profile/presentation/public_profile_screen.dart';
import '../services/home_feed_service.dart';

class HomeFeedSection extends StatefulWidget {
  const HomeFeedSection({
    required this.localeController,
    super.key,
  });

  final LocaleController localeController;

  @override
  State<HomeFeedSection> createState() => _HomeFeedSectionState();
}

class _HomeFeedSectionState extends State<HomeFeedSection> {
  final HomeFeedService _service = HomeFeedService();
  late Future<List<HomePost>> _feed = _service.fetchFeed();

  bool get ar =>
      (widget.localeController.locale?.languageCode ??
          Localizations.localeOf(context).languageCode) ==
      'ar';

  void _reload() {
    if (!mounted) return;
    setState(() => _feed = _service.fetchFeed());
  }

  Future<void> _createPost() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _CreatePostSheet(
        service: _service,
        isArabic: ar,
      ),
    );
    if (created == true) _reload();
  }

  Future<void> _comments(HomePost post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _PostCommentsSheet(
        service: _service,
        post: post,
        isArabic: ar,
      ),
    );
    _reload();
  }

  Future<void> _share(HomePost post) async {
    final text = [
      if (post.text.trim().isNotEmpty) post.text.trim(),
      if (post.mediaUrl.trim().isNotEmpty) post.mediaUrl.trim(),
      'WorldVoice',
    ].join('\n\n');
    await SharePlus.instance.share(ShareParams(text: text));
    try {
      await _service.recordShare(post.id);
    } catch (_) {}
    _reload();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _createPost,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.person_rounded)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ar
                          ? 'شارك شيئًا مع العالم...'
                          : 'Share something with the world...',
                    ),
                  ),
                  const Icon(Icons.add_photo_alternate_outlined),
                  const SizedBox(width: 8),
                  const Icon(Icons.videocam_outlined),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<HomePost>>(
          future: _feed,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        ar
                            ? 'تعذر تحميل المنشورات الآن.'
                            : 'Could not load posts right now.',
                      ),
                      TextButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(ar ? 'إعادة المحاولة' : 'Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final posts = snapshot.data ?? const <HomePost>[];
            if (posts.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Text(
                    ar
                        ? 'لا توجد منشورات بعد. كن أول من ينشر.'
                        : 'No posts yet. Be the first to post.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return Column(
              children: [
                for (final post in posts) ...[
                  _HomePostCard(
                    post: post,
                    isArabic: ar,
                    mine: uid == post.authorId,
                    localeController: widget.localeController,
                    onLike: () async {
                      try {
                        await _service.toggleLike(post);
                        _reload();
                      } catch (error) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              error.toString().replaceFirst('Bad state: ', ''),
                            ),
                          ),
                        );
                      }
                    },
                    onComments: () => _comments(post),
                    onShare: () => _share(post),
                    onDelete: uid == post.authorId
                        ? () async {
                            await _service.deletePost(post.id);
                            _reload();
                          }
                        : null,
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet({
    required this.service,
    required this.isArabic,
  });

  final HomeFeedService service;
  final bool isArabic;

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final TextEditingController _text = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _media;
  String? _mediaType;
  VideoPlayerController? _video;
  bool _posting = false;

  Future<void> _pick(String type) async {
    XFile? file;
    if (type == 'video') {
      file = await _picker.pickVideo(source: ImageSource.gallery);
    } else {
      file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1800,
      );
    }
    if (file == null || !mounted) return;
    await _video?.dispose();
    _video = null;
    if (type == 'video') {
      final controller = VideoPlayerController.file(File(file.path));
      await controller.initialize();
      await controller.setLooping(true);
      _video = controller;
    }
    setState(() {
      _media = file;
      _mediaType = type;
    });
  }

  Future<void> _publish() async {
    if (_posting) return;
    final text = _text.text.trim();
    if (text.isEmpty && _media == null) return;
    setState(() => _posting = true);
    try {
      await widget.service.createPost(
        text: text,
        media: _media == null ? null : File(_media!.path),
        mediaType: _mediaType,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _posting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.isArabic;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        2,
        16,
        18 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                ar ? 'إنشاء منشور' : 'Create post',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _text,
              minLines: 3,
              maxLines: 8,
              maxLength: 3000,
              decoration: InputDecoration(
                hintText: ar ? 'اكتب شيئًا...' : 'Write something...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            if (_media != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: _mediaType == 'video' && _video != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            VideoPlayer(_video!),
                            Center(
                              child: IconButton.filled(
                                onPressed: () {
                                  if (_video!.value.isPlaying) {
                                    _video!.pause();
                                  } else {
                                    _video!.play();
                                  }
                                  setState(() {});
                                },
                                icon: Icon(
                                  _video!.value.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Image.file(File(_media!.path), fit: BoxFit.cover),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () async {
                    await _video?.dispose();
                    _video = null;
                    setState(() {
                      _media = null;
                      _mediaType = null;
                    });
                  },
                  icon: const Icon(Icons.close_rounded),
                  label: Text(ar ? 'إزالة' : 'Remove'),
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _posting ? null : () => _pick('image'),
                    icon: const Icon(Icons.photo_outlined),
                    label: Text(ar ? 'صورة' : 'Photo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _posting ? null : () => _pick('video'),
                    icon: const Icon(Icons.videocam_outlined),
                    label: Text(ar ? 'فيديو' : 'Video'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _posting ? null : _publish,
                icon: _posting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _posting
                      ? (ar ? 'جاري النشر...' : 'Publishing...')
                      : (ar ? 'نشر' : 'Post'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePostCard extends StatelessWidget {
  const _HomePostCard({
    required this.post,
    required this.isArabic,
    required this.mine,
    required this.localeController,
    required this.onLike,
    required this.onComments,
    required this.onShare,
    this.onDelete,
  });

  final HomePost post;
  final bool isArabic;
  final bool mine;
  final LocaleController localeController;
  final VoidCallback onLike;
  final VoidCallback onComments;
  final VoidCallback onShare;
  final VoidCallback? onDelete;

  String _age() {
    final diff = DateTime.now().millisecondsSinceEpoch - post.createdAtMs;
    if (diff < 60000) return isArabic ? 'الآن' : 'now';
    if (diff < 3600000) {
      final m = (diff / 60000).floor();
      return isArabic ? 'منذ ' + m.toString() + ' د' : m.toString() + 'm';
    }
    final h = (diff / 3600000).floor();
    if (h < 24) {
      return isArabic ? 'منذ ' + h.toString() + ' س' : h.toString() + 'h';
    }
    final d = (h / 24).floor();
    return isArabic ? 'منذ ' + d.toString() + ' ي' : d.toString() + 'd';
  }

  @override
  Widget build(BuildContext context) {
    final photo = post.authorPhotoUrl.trim();
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PublicProfileScreen(
                    userId: post.authorId,
                    localeController: localeController,
                  ),
                ),
              ),
              child: CircleAvatar(
                backgroundImage: photo.isEmpty ? null : NetworkImage(photo),
                child:
                    photo.isEmpty ? const Icon(Icons.person_rounded) : null,
              ),
            ),
            title: Text(
              post.authorName,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(_age()),
            trailing: mine && onDelete != null
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') onDelete!();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          isArabic ? 'حذف المنشور' : 'Delete post',
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          if (post.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
              child: Text(
                post.text,
                style: const TextStyle(fontSize: 15.5, height: 1.35),
              ),
            ),
          if (post.hasImage)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                post.mediaUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.broken_image_outlined, size: 44),
                ),
              ),
            ),
          if (post.hasVideo) _FeedVideo(url: post.mediaUrl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onLike,
                  icon: Icon(
                    post.likedByMe
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: post.likedByMe ? Colors.redAccent : null,
                  ),
                  label: Text(post.likeCount.toString()),
                ),
                TextButton.icon(
                  onPressed: onComments,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: Text(post.commentCount.toString()),
                ),
                TextButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share_outlined),
                  label: Text(post.shareCount.toString()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedVideo extends StatefulWidget {
  const _FeedVideo({required this.url});
  final String url;

  @override
  State<_FeedVideo> createState() => _FeedVideoState();
}

class _FeedVideoState extends State<_FeedVideo> {
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
      await _controller.setLooping(true);
      await _controller.setVolume(0);
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
    return AspectRatio(
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
                  PositionedDirectional(
                    end: 8,
                    bottom: 8,
                    child: IconButton.filledTonal(
                      onPressed: () async {
                        final muted = _controller.value.volume == 0;
                        await _controller.setVolume(muted ? 1 : 0);
                        if (mounted) setState(() {});
                      },
                      icon: Icon(
                        _controller.value.volume == 0
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                      ),
                    ),
                  ),
                ],
              )
            : const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
      ),
    );
  }
}

class _PostCommentsSheet extends StatefulWidget {
  const _PostCommentsSheet({
    required this.service,
    required this.post,
    required this.isArabic,
  });

  final HomeFeedService service;
  final HomePost post;
  final bool isArabic;

  @override
  State<_PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<_PostCommentsSheet> {
  final TextEditingController _input = TextEditingController();
  late Future<List<HomePostComment>> _comments =
      widget.service.fetchComments(widget.post.id);
  bool _sending = false;

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.service.addComment(
        postId: widget.post.id,
        text: text,
      );
      _input.clear();
      setState(() {
        _comments = widget.service.fetchComments(widget.post.id);
        _sending = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.isArabic;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .78,
      child: Column(
        children: [
          ListTile(
            title: Text(
              ar ? 'التعليقات' : 'Comments',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<HomePostComment>>(
              future: _comments,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final comments = snapshot.data!;
                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      ar ? 'لا توجد تعليقات بعد.' : 'No comments yet.',
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: comments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final photo = comment.authorPhotoUrl.trim();
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage:
                              photo.isEmpty ? null : NetworkImage(photo),
                          child: photo.isEmpty
                              ? const Icon(Icons.person_rounded, size: 18)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment.authorName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(comment.text),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              10 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    maxLength: 800,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText:
                          ar ? 'اكتب تعليقًا...' : 'Write a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
