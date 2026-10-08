import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../services/story_service.dart';

class CreateStorySheet extends StatefulWidget {
  const CreateStorySheet({
    required this.service,
    required this.isArabic,
    super.key,
  });

  final StoryService service;
  final bool isArabic;

  @override
  State<CreateStorySheet> createState() => _CreateStorySheetState();
}

class _CreateStorySheetState extends State<CreateStorySheet> {
  final ImagePicker _picker = ImagePicker();
  XFile? _media;
  String _kind = 'image';
  String _audience = 'everyone';
  int _durationMs = 7000;
  bool _uploading = false;
  bool _loadingEntitlements = true;
  bool _isVip = false;
  Set<String> _closeFriends = <String>{};
  VideoPlayerController? _video;

  bool get ar => widget.isArabic;

  @override
  void initState() {
    super.initState();
    _loadEntitlements();
  }

  Future<void> _loadEntitlements() async {
    try {
      final state = await widget.service.fetchCloseFriendState();
      if (!mounted) return;
      setState(() {
        _isVip = state.isVip;
        _closeFriends = state.userIds;
        _loadingEntitlements = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingEntitlements = false);
    }
  }

  Future<void> _pick({
    required String kind,
    required ImageSource source,
  }) async {
    if (_uploading) return;
    XFile? selected;
    if (kind == 'video') {
      selected = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 90),
      );
    } else {
      selected = await _picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1440,
      );
    }
    if (selected == null || !mounted) return;

    await _video?.dispose();
    _video = null;

    if (kind == 'video') {
      final controller = VideoPlayerController.file(File(selected.path));
      try {
        await controller.initialize();
        final duration = controller.value.duration;
        if (duration > const Duration(seconds: 90)) {
          await controller.dispose();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ar
                    ? 'الفيديو لازم يكون 90 ثانية أو أقل.'
                    : 'Story videos must be 90 seconds or shorter.',
              ),
            ),
          );
          return;
        }
        await controller.setLooping(true);
        await controller.play();
        _video = controller;
        _durationMs = duration.inMilliseconds.clamp(1, 90000);
      } catch (_) {
        await controller.dispose();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar
                  ? 'تعذر قراءة هذا الفيديو.'
                  : 'Could not read this video.',
            ),
          ),
        );
        return;
      }
    } else {
      _durationMs = 7000;
    }

    setState(() {
      _media = selected;
      _kind = kind;
    });
  }

  Future<void> _manageCloseFriends() async {
    if (!_isVip) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ar
                ? 'Close Friends متاح لمستخدمي VIP فقط.'
                : 'Close Friends is available to VIP members only.',
          ),
        ),
      );
      return;
    }

    List<StoryCloseFriendCandidate> candidates;
    try {
      candidates = await widget.service.fetchCloseFriendCandidates();
    } catch (error) {
      if (!mounted) return;
      final raw = error.toString().replaceFirst('Bad state: ', '');
      final message = ar && raw.contains('Story upload timed out')
          ? 'رفع الستوري أخذ وقتًا طويلًا. تأكد من الإنترنت وحاول مرة ثانية.'
          : raw;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }
    if (!mounted) return;

    final working = {..._closeFriends};
    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheet) => StatefulBuilder(
        builder: (context, setSheetState) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF13A06E),
                  child: Icon(Icons.star_rounded, color: Colors.white),
                ),
                title: Text(
                  ar ? 'الأصدقاء المقرّبون' : 'Close Friends',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  ar
                      ? 'اختر من الأشخاص الذين تتابعهم.'
                      : 'Choose from people you follow.',
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: candidates.isEmpty
                    ? Center(
                        child: Text(
                          ar
                              ? 'تابع أشخاصًا أولًا لإضافتهم هنا.'
                              : 'Follow people first to add them here.',
                        ),
                      )
                    : ListView.builder(
                        itemCount: candidates.length,
                        itemBuilder: (context, index) {
                          final person = candidates[index];
                          final checked = working.contains(person.uid);
                          return CheckboxListTile(
                            value: checked,
                            onChanged: (value) {
                              setSheetState(() {
                                if (value == true) {
                                  working.add(person.uid);
                                } else {
                                  working.remove(person.uid);
                                }
                              });
                            },
                            secondary: CircleAvatar(
                              backgroundImage: person.photoUrl.trim().isEmpty
                                  ? null
                                  : NetworkImage(person.photoUrl),
                              child: person.photoUrl.trim().isEmpty
                                  ? const Icon(Icons.person_rounded)
                                  : null,
                            ),
                            title: Text(person.displayName),
                            subtitle: person.username.trim().isEmpty
                                ? null
                                : Text('@${person.username}'),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(sheet, working),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(ar ? 'حفظ القائمة' : 'Save list'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected == null) return;
    try {
      final saved = await widget.service.saveCloseFriends(selected);
      if (!mounted) return;
      setState(() => _closeFriends = saved);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  Future<void> _publish() async {
    final media = _media;
    if (media == null || _uploading) return;
    if (_audience == 'close_friends' && !_isVip) return;
    if (_audience == 'close_friends' && _closeFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ar
                ? 'أضف شخصًا واحدًا على الأقل إلى Close Friends.'
                : 'Add at least one person to Close Friends.',
          ),
        ),
      );
      return;
    }

    await _video?.pause();
    if (!mounted) return;
    setState(() => _uploading = true);
    try {
      await widget.service.uploadStory(
        file: media,
        kind: _kind,
        audience: _audience,
        durationMs: _durationMs,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  Widget _sourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: FilledButton.tonalIcon(
        onPressed: _uploading ? null : onTap,
        icon: Icon(icon),
        label: Text(label, textAlign: TextAlign.center),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final closeFriendEnabled = !_loadingEntitlements && _isVip;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  ar ? 'إنشاء ستوري' : 'Create Story',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                subtitle: Text(
                  ar
                      ? 'صورة أو فيديو حتى 90 ثانية • تختفي بعد 24 ساعة'
                      : 'Photo or video up to 90 seconds • disappears after 24 hours',
                ),
              ),
              if (_media != null) ...[
                AspectRatio(
                  aspectRatio: 9 / 14,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ColoredBox(
                      color: Colors.black,
                      child: _kind == 'video' && _video != null
                          ? VideoPlayer(_video!)
                          : Image.file(
                              File(_media!.path),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  _sourceButton(
                    icon: Icons.photo_library_outlined,
                    label: ar ? 'صورة' : 'Photo',
                    onTap: () => _pick(
                      kind: 'image',
                      source: ImageSource.gallery,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _sourceButton(
                    icon: Icons.video_library_outlined,
                    label: ar ? 'فيديو' : 'Video',
                    onTap: () => _pick(
                      kind: 'video',
                      source: ImageSource.gallery,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _sourceButton(
                    icon: Icons.photo_camera_outlined,
                    label: ar ? 'كاميرا صورة' : 'Camera',
                    onTap: () => _pick(
                      kind: 'image',
                      source: ImageSource.camera,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _sourceButton(
                    icon: Icons.videocam_outlined,
                    label: ar ? 'كاميرا فيديو' : 'Record',
                    onTap: () => _pick(
                      kind: 'video',
                      source: ImageSource.camera,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  ar ? 'من يشوف الستوري؟' : 'Who can see this story?',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment<String>(
                    value: 'everyone',
                    icon: const Icon(Icons.public_rounded),
                    label: Text(ar ? 'الكل' : 'Everyone'),
                  ),
                  ButtonSegment<String>(
                    value: 'close_friends',
                    enabled: closeFriendEnabled,
                    icon: const Icon(Icons.star_rounded),
                    label: const Text('Close Friends'),
                  ),
                ],
                selected: {_audience},
                onSelectionChanged: (value) {
                  final next = value.first;
                  if (next == 'close_friends' && !_isVip) return;
                  setState(() => _audience = next);
                },
              ),
              if (!_loadingEntitlements && !_isVip)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    ar
                        ? 'Close Friends ميزة VIP.'
                        : 'Close Friends is a VIP feature.',
                    style: const TextStyle(
                      color: Color(0xFFB88712),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (_isVip) ...[
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF13A06E),
                    child: Icon(Icons.star_rounded, color: Colors.white),
                  ),
                  title: Text(ar ? 'إدارة Close Friends' : 'Manage Close Friends'),
                  subtitle: Text(
                    ar
                        ? '${_closeFriends.length} شخص'
                        : '${_closeFriends.length} people',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _manageCloseFriends,
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _media == null || _uploading ? null : _publish,
                  icon: _uploading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    _uploading
                        ? (ar ? 'جاري رفع الستوري...' : 'Uploading Story...')
                        : (ar ? 'نشر الستوري' : 'Share Story'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
