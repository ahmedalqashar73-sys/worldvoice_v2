import 'package:flutter/material.dart';
import '../services/story_service.dart';

/// Only server-authorized viewers can retrieve engagement; never query other
/// users' Firestore reaction documents directly from the phone.
class StoryInteractionSheet extends StatefulWidget {
  const StoryInteractionSheet({
    required this.story,
    required this.service,
    required this.owner,
    required this.isArabic,
    super.key,
  });
  final StoryItem story;
  final StoryService service;
  final bool owner;
  final bool isArabic;

  @override
  State<StoryInteractionSheet> createState() => _StoryInteractionSheetState();
}

class _StoryInteractionSheetState extends State<StoryInteractionSheet> {
  final TextEditingController _input = TextEditingController();
  late Future<Map<String, dynamic>> _interaction = _refresh();
  bool _posting = false;

  Future<Map<String, dynamic>> _refresh() =>
      widget.service.fetchStoryInteractions(widget.story.id);

  Future<void> _submit() async {
    if (_posting || _input.text.trim().isEmpty) return;
    setState(() => _posting = true);
    try {
      await widget.service.commentOnStory(widget.story.id, _input.text.trim());
      _input.clear();
      if (mounted) {
        setState(() => _interaction = _refresh());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isArabic
              ? 'تم إرسال التعليق لصاحب الستوري'
              : 'Comment sent to Story owner')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Widget _person(Map<dynamic, dynamic> data, String subtitle) => ListTile(
    leading: CircleAvatar(
      backgroundImage: (data['photoUrl'] ?? data['actorPhotoUrl'] ?? '')
              .toString().isEmpty
          ? null
          : NetworkImage((data['photoUrl'] ?? data['actorPhotoUrl']).toString()),
      child: (data['photoUrl'] ?? data['actorPhotoUrl'] ?? '')
              .toString().isEmpty ? const Icon(Icons.person) : null,
    ),
    title: Text((data['displayName'] ?? data['actorName'] ?? 'WorldVoice').toString(),
        maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Text(subtitle, maxLines: 3, overflow: TextOverflow.ellipsis),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16,
            MediaQuery.viewInsetsOf(context).bottom + 14),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _interaction,
          builder: (context, snap) {
            if (!snap.hasData) {
              return SizedBox(height: 160, child: Center(child: snap.hasError
                  ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(snap.error.toString(),
                      textAlign: TextAlign.center),
                    TextButton(onPressed: () =>
                        setState(() => _interaction = _refresh()),
                        child: Text(widget.isArabic ? 'إعادة المحاولة' : 'Retry')),
                  ])
                  : const CircularProgressIndicator()));
            }
            final data = snap.data!;
            final likes = (data['likes'] as List?)?.whereType<Map>().toList() ?? [];
            final comments =
                (data['comments'] as List?)?.whereType<Map>().toList() ?? [];
            final allowReplies = data['allowReplies'] != false;
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .72),
              child: ListView(shrinkWrap: true, children: [
                Row(children: [
                  Expanded(child: Text(widget.isArabic ? 'تفاعلات الستوري' :
                      'Story activity', style: Theme.of(context)
                          .textTheme.titleLarge)),
                  IconButton(onPressed: () => setState(() =>
                      _interaction = _refresh()),
                      icon: const Icon(Icons.refresh)),
                ]),
                Text(widget.isArabic
                    ? '${data['likesCount'] ?? 0} إعجاب • ${data['commentsCount'] ?? 0} تعليق'
                    : '${data['likesCount'] ?? 0} likes • ${data['commentsCount'] ?? 0} comments'),
                const Divider(),
                if (widget.owner) ...[
                  Text(widget.isArabic ? 'من أعجب بالستوري' : 'Liked by',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  for (final item in likes)
                    _person(item, widget.isArabic ? 'أعجب بالستوري' : 'Liked Story'),
                  if (likes.isEmpty) Text(widget.isArabic
                      ? 'ما فيه إعجابات بعد' : 'No likes yet'),
                  const SizedBox(height: 8),
                  Text(widget.isArabic ? 'التعليقات' : 'Comments',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  for (final item in comments)
                    _person(item, (item['text'] ?? '').toString()),
                  if (comments.isEmpty) Text(widget.isArabic
                      ? 'ما فيه تعليقات بعد' : 'No comments yet'),
                  const SizedBox(height: 10),
                  Text(widget.isArabic
                      ? 'الإعجابات والتعليقات تظهر لك أنت فقط.'
                      : 'Only you can see these likes and comments.',
                      style: Theme.of(context).textTheme.bodySmall),
                ] else if (allowReplies) ...[
                  TextField(
                    controller: _input,
                    maxLength: 350,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: widget.isArabic
                          ? 'اكتب تعليقًا لصاحب الستوري'
                          : 'Comment privately to Story owner',
                      suffixIcon: IconButton(
                        onPressed: _posting ? null : _submit,
                        icon: const Icon(Icons.send_rounded)),
                    ),
                  ),
                ] else Text(widget.isArabic
                    ? 'صاحب الستوري أوقف التعليقات والردود.'
                    : 'The Story owner has disabled comments and replies.'),
              ]),
            );
          },
        ),
      ),
    );
  }
}

class StorySettingsSheet extends StatefulWidget {
  const StorySettingsSheet({required this.service, required this.isArabic,
    super.key});
  final StoryService service;
  final bool isArabic;

  @override
  State<StorySettingsSheet> createState() => _StorySettingsSheetState();
}

class _StorySettingsSheetState extends State<StorySettingsSheet> {
  late Future<Map<String, dynamic>> _settings = widget.service.fetchStoryPreferences();
  bool _saving = false;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _settings,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox(height: 140, child: Center(child: snapshot.hasError
                ? TextButton(onPressed: () => setState(() =>
                    _settings = widget.service.fetchStoryPreferences()),
                    child: Text(widget.isArabic ? 'إعادة المحاولة' : 'Retry'))
                : const CircularProgressIndicator()));
          }
          final replies = snapshot.data!['allowReplies'] != false;
          final notify = snapshot.data!['notifyActivity'] != false;
          Future<void> update({bool? allowReplies, bool? notifyActivity}) async {
            if (_saving) return;
            setState(() => _saving = true);
            try {
              final r = allowReplies ?? replies;
              final n = notifyActivity ?? notify;
              await widget.service.updateStoryPreferences(
                allowReplies: r, notifyActivity: n);
              if (mounted) {
                setState(() => _settings = Future.value(<String, dynamic>{
                  'allowReplies': r, 'notifyActivity': n}));
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text(e.toString())));
              }
            } finally {
              if (mounted) setState(() => _saving = false);
            }
          }
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.isArabic ? 'خصوصية الاستوري' : 'Story privacy',
              style: Theme.of(context).textTheme.titleLarge),
            SwitchListTile(
              title: Text(widget.isArabic
                  ? 'السماح بالتعليقات والرد في الدردشة'
                  : 'Allow comments and chat replies'),
              subtitle: Text(widget.isArabic
                  ? 'عند الإيقاف لا يستطيع الآخرون التعليق أو فتح رد على الستوري'
                  : 'When off, other viewers cannot comment or reply from Stories'),
              value: replies, onChanged: _saving
                  ? null : (value) => update(allowReplies: value)),
            SwitchListTile(
              title: Text(widget.isArabic
                  ? 'إشعارات الإعجابات والتعليقات'
                  : 'Like and comment notifications'),
              value: notify, onChanged: _saving
                  ? null : (value) => update(notifyActivity: value)),
          ]);
        },
      ),
    ),
  );
}
