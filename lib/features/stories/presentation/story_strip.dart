import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/story_service.dart';
import 'create_story_sheet.dart';
import 'story_viewer_screen.dart';

typedef StoryReplyCallback = Future<void> Function(StoryItem story);

class StoryStrip extends StatefulWidget {
  const StoryStrip({
    required this.isArabic,
    this.onReply,
    super.key,
  });

  final bool isArabic;
  final StoryReplyCallback? onReply;

  @override
  State<StoryStrip> createState() => _StoryStripState();
}

class _StoryStripState extends State<StoryStrip>
    with WidgetsBindingObserver {
  late final StoryService _service = StoryService();
  List<StoryItem> _lastStories =
      StoryService.cachedFeedFor(FirebaseAuth.instance.currentUser?.uid);
  late Future<List<StoryItem>> _feed = _loadFeed();
  Timer? _refreshTimer;

  Future<List<StoryItem>> _loadFeed() async {
    final loaded = await _service.fetchFeed();
    if (mounted) _lastStories = loaded;
    return loaded;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Refresh without discarding the last list, even if Chat stays mounted.
    _refreshTimer = Timer.periodic(const Duration(seconds: 90), (_) {
      if (mounted &&
          WidgetsBinding.instance.lifecycleState ==
              AppLifecycleState.resumed) {
        _refresh();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }
  late final Stream<DocumentSnapshot<Map<String, dynamic>>>? _ownProfileStream =
      FirebaseAuth.instance.currentUser == null
          ? null
          : FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .snapshots();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  void _refresh() {
    if (!mounted) return;
    setState(() => _feed = _loadFeed());
  }

  Future<void> _createStory() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CreateStorySheet(
        service: _service,
        isArabic: widget.isArabic,
      ),
    );
    if (created == true) {
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic
                  ? 'تم نشر الستوري بنجاح.'
                  : 'Story published successfully.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _openStories(List<StoryItem> stories) async {
    if (stories.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StoryViewerScreen(
          stories: stories,
          service: _service,
          isArabic: widget.isArabic,
          onReply: widget.onReply,
          onChanged: _refresh,
        ),
      ),
    );
    _refresh();
  }

  Map<String, List<StoryItem>> _group(List<StoryItem> stories) {
    final result = <String, List<StoryItem>>{};
    for (final story in stories) {
      result.putIfAbsent(story.ownerId, () => <StoryItem>[]).add(story);
    }
    for (final list in result.values) {
      list.sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));
    }
    return result;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) return const SizedBox.shrink();

    return SizedBox(
      height: 116,
      child: FutureBuilder<List<StoryItem>>(
        future: _feed,
        builder: (context, snapshot) {
          final now = DateTime.now().millisecondsSinceEpoch;
          // Don't clear all Story circles during network retry/cold-start.
          // Cache is only from the same signed-in user, and never expired.
          final stories = (snapshot.data ?? _lastStories)
              .where((story) => story.expiresAtMs > now)
              .toList(growable: false);
          final failedToLoad = snapshot.hasError;
          final grouped = _group(stories);
          final mine = grouped.remove(uid) ?? const <StoryItem>[];
          final groups = grouped.entries.toList()
            ..sort((a, b) {
              final aTime =
                  a.value.isEmpty ? 0 : a.value.last.createdAtMs;
              final bTime =
                  b.value.isEmpty ? 0 : b.value.last.createdAtMs;
              return bTime.compareTo(aTime);
            });

          final ownPhoto = mine.isNotEmpty
              ? mine.last.ownerPhotoUrl
              : FirebaseAuth.instance.currentUser?.photoURL ?? '';

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: 1 + groups.length + (failedToLoad ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _ownProfileStream,
                  builder: (context, profileSnapshot) {
                    final profilePhoto =
                        (profileSnapshot.data?.data()?['photoUrl'] ?? '')
                            .toString()
                            .trim();
                    return _StoryBubble(
                      name: widget.isArabic ? 'ستوريك' : 'Your Story',
                      photoUrl:
                          profilePhoto.isNotEmpty ? profilePhoto : ownPhoto,
                      hasStory: mine.isNotEmpty,
                      closeFriends:
                          mine.any((story) => story.isCloseFriends),
                      showAdd: true,
                      onTap: () =>
                          mine.isEmpty ? _createStory() : _openStories(mine),
                      onAdd: _createStory,
                    );
                  },
                );
              }

              if (failedToLoad && index == 1) {
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _refresh,
                  child: SizedBox(
                    width: 154,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.refresh_rounded, color: Colors.orange),
                        const SizedBox(height: 4),
                        Text(
                          widget.isArabic
                              ? 'تعذر تحميل الستوري. اضغط للمحاولة مجددًا'
                              : 'Stories unavailable. Tap to retry.',
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                );
              }
              final entry = groups[index - 1 - (failedToLoad ? 1 : 0)];
              final list = entry.value;
              final latest = list.last;
              return _StoryBubble(
                name: latest.ownerName,
                photoUrl: latest.ownerPhotoUrl,
                hasStory: true,
                closeFriends: list.any((story) => story.isCloseFriends),
                onTap: () => _openStories(list),
              );
            },
          );
        },
      ),
    );
  }
}

class StoryProfileRing extends StatefulWidget {
  const StoryProfileRing({
    required this.ownerId,
    required this.isArabic,
    required this.child,
    this.onReply,
    super.key,
  });

  final String ownerId;
  final bool isArabic;
  final Widget child;
  final StoryReplyCallback? onReply;

  @override
  State<StoryProfileRing> createState() => _StoryProfileRingState();
}

class _StoryProfileRingState extends State<StoryProfileRing> {
  late final StoryService _service = StoryService();
  late Future<List<StoryItem>> _stories = _load();

  Future<List<StoryItem>> _load() async {
    final feed = await _service.fetchFeed();
    return feed
        .where((story) => story.ownerId == widget.ownerId)
        .toList(growable: false)
      ..sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));
  }

  Future<void> _open(List<StoryItem> stories) async {
    if (stories.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StoryViewerScreen(
          stories: stories,
          service: _service,
          isArabic: widget.isArabic,
          onReply: widget.onReply,
          onChanged: () {
            if (mounted) setState(() => _stories = _load());
          },
        ),
      ),
    );
    if (mounted) setState(() => _stories = _load());
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StoryItem>>(
      future: _stories,
      builder: (context, snapshot) {
        final stories = snapshot.data ??
            StoryService.cachedFeedFor(FirebaseAuth.instance.currentUser?.uid)
                .where((story) => story.ownerId == widget.ownerId)
                .toList(growable: false);
        final active = stories.isNotEmpty;
        final close = stories.any((story) => story.isCloseFriends);
        return GestureDetector(
          onTap: active ? () => _open(stories) : null,
          child: DecoratedBox(
            decoration: active
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: close
                        ? const LinearGradient(
                            colors: [
                              Color(0xFF16B978),
                              Color(0xFF6DE0A8),
                            ],
                          )
                        : const LinearGradient(
                            colors: [
                              Color(0xFF0D8C63),
                              Color(0xFFFFD45D),
                            ],
                          ),
                  )
                : const BoxDecoration(shape: BoxShape.circle),
            child: Padding(
              padding: EdgeInsets.all(active ? 3 : 0),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({
    required this.name,
    required this.photoUrl,
    required this.hasStory,
    required this.closeFriends,
    required this.onTap,
    this.showAdd = false,
    this.onAdd,
  });

  final String name;
  final String photoUrl;
  final bool hasStory;
  final bool closeFriends;
  final VoidCallback onTap;
  final bool showAdd;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final photo = photoUrl.trim();
    final gradient = closeFriends
        ? const LinearGradient(
            colors: [Color(0xFF10A96E), Color(0xFF81E9B8)],
          )
        : const LinearGradient(
            colors: [Color(0xFF0C8A61), Color(0xFFFFD15A)],
          );

    return SizedBox(
      width: 78,
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  padding: EdgeInsets.all(hasStory ? 3 : 1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasStory ? gradient : null,
                    border: hasStory
                        ? null
                        : Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant,
                          ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      backgroundImage: photo.isEmpty
                          ? null
                          : NetworkImage(photo),
                      child: photo.isEmpty
                          ? const Icon(Icons.person_rounded, size: 30)
                          : null,
                    ),
                  ),
                ),
                if (showAdd)
                  PositionedDirectional(
                    end: -1,
                    bottom: 1,
                    child: GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        width: 23,
                        height: 23,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C8A61),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                if (closeFriends && !showAdd)
                  const PositionedDirectional(
                    end: -1,
                    bottom: 1,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Color(0xFF13A06E),
                      child: Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
