import 'package:flutter/material.dart';

import '../services/story_service.dart';
import 'story_viewer_screen.dart';

/// Owner-only inbox. Entries are authenticated and read through the dedicated
/// Story backend rather than exposing friends' private Firestore collections.
class StoryNotificationsScreen extends StatefulWidget {
  const StoryNotificationsScreen({required this.isArabic, super.key});
  final bool isArabic;
  @override
  State<StoryNotificationsScreen> createState() => _StoryNotificationsScreenState();
}

class _StoryNotificationsScreenState extends State<StoryNotificationsScreen> {
  final StoryService _service = StoryService();
  late Future<List<Map<String, dynamic>>> _events = _service.fetchStoryNotifications();

  void _refresh() => setState(() => _events = _service.fetchStoryNotifications());

  Future<void> _openStory(Map<String, dynamic> event) async {
    try {
      final feed = await _service.fetchFeed();
      final matching = feed.where((s) => s.id == event['storyId']).toList();
      if (!mounted) return;
      if (matching.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          widget.isArabic ? 'الستوري انتهت أو حُذفت' : 'This Story expired or was deleted')));
        return;
      }
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => StoryViewerScreen(stories: matching,
          service: _service, isArabic: widget.isArabic, onChanged: _refresh)));
      if (mounted) _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.isArabic ? 'إشعارات الاستوري' : 'Story notifications'),
      actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.isArabic ? 'تعذر تحميل الإشعارات' :
                'Could not load notifications'),
            TextButton(onPressed: _refresh,
                child: Text(widget.isArabic ? 'إعادة المحاولة' : 'Retry')),
          ]));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final events = snapshot.data!;
        if (events.isEmpty) {
          return Center(child: Text(widget.isArabic
              ? 'ما فيه إعجابات أو تعليقات على الستوري بعد'
              : 'No Story likes or comments yet'));
        }
        return ListView.separated(
          itemCount: events.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final event = events[i];
            final photo = (event['actorPhotoUrl'] ?? '').toString();
            final name = (event['actorName'] ?? 'WorldVoice').toString();
            final liked = event['type'] == 'like';
            final action = liked
                ? (widget.isArabic ? 'أعجب بالستوري' : 'liked your Story')
                : (widget.isArabic ? 'علّق على الستوري' : 'commented on your Story');
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo.isEmpty ? Icon(liked
                    ? Icons.favorite : Icons.mode_comment_outlined) : null,
              ),
              title: Text('$name $action'),
              subtitle: liked ? null : Text((event['text'] ?? '').toString(),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openStory(event),
            );
          },
        );
      },
    ),
  );
}
