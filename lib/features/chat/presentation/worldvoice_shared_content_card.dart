import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import '../../live/presentation/live_screen.dart';
import '../../rooms/data/room_mode.dart';
import '../../rooms/presentation/agora_voice_room_screen.dart';
import '../../rooms/services/agora_voice_room_controller.dart';
import '../../stories/services/story_service.dart';
import '../../stories/presentation/story_viewer_screen.dart';

enum SharedContentKind { live, room, story }

class WorldVoiceSharedLink {
  const WorldVoiceSharedLink(this.kind, this.id);
  final SharedContentKind kind;
  final String id;
  static final RegExp _pattern = RegExp(
    r'worldvoice://(live|room|story)/([A-Za-z0-9_-]{4,120})(?![A-Za-z0-9_-])');

  static WorldVoiceSharedLink? parse(String text) {
    final match = _pattern.firstMatch(text);
    if (match == null) return null;
    final kind = switch (match.group(1)) {
      'room' => SharedContentKind.room,
      'story' => SharedContentKind.story,
      _ => SharedContentKind.live,
    };
    return WorldVoiceSharedLink(kind, match.group(2)!);
  }
}

class WorldVoiceSharedContentCard extends StatelessWidget {
  const WorldVoiceSharedContentCard({required this.text, super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final link = WorldVoiceSharedLink.parse(text);
    if (link == null) return Text(text);
    return switch (link.kind) {
      SharedContentKind.live => WorldVoiceLiveSharedCard(shareText: text),
      SharedContentKind.room => _RoomCard(id: link.id, text: text),
      SharedContentKind.story => _StoryCard(id: link.id),
    };
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.id, required this.text});
  final String id, text;

  Future<void> _join(BuildContext context, Map<String, dynamic> room) async {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    if (room['isOpen'] != true || room['isPrivate'] == true ||
        room['vipOnly'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ar ? 'الدخول غير متاح لهذه الغرفة.'
            : 'This room is not open for public entry.')));
      return;
    }
    final locale = LocaleController();
    try {
      await locale.load();
      if (!context.mounted) return;
      await Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) => AgoraVoiceRoomScreen(
          channelId: id,
          roomName: (room['name'] ?? 'WorldVoice Room').toString(),
          initialRole: AgoraRoomRole.listener,
          roomLanguageCode: (room['languageCode'] ?? 'en').toString(),
          initialMode: RoomMode.values.firstWhere(
            (mode) => mode.name == room['mode'],
            orElse: () => RoomMode.chat,
          ),
          initialShowTeacherAiSeat: room['showTeacherAiSeat'] == true,
          localeController: locale,
        ),
      ));
    } finally {
      locale.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('rooms').doc(id).snapshots(),
      builder: (context, snapshot) {
        final room = snapshot.data?.data();
        final open = room?['isOpen'] == true;
        final canJoin = open && room?['isPrivate'] != true &&
            room?['vipOnly'] != true;
        final fallback = text.split('\n');
        final title = (room?['name'] ??
            (fallback.length > 1 ? fallback[1] : 'WorldVoice Room')).toString();
        final host = (room?['hostName'] ?? 'WorldVoice').toString();
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Material(
            color: const Color(0xFF183E36),
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: canJoin ? () => _join(context, room!) : null,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 125,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF174937), Color(0xFF1A6A73),
                          Color(0xFF322C67)])),
                    child: Stack(children: [
                      const Center(child: Icon(Icons.record_voice_over_rounded,
                        size: 70, color: Color(0xAADDFFEA))),
                      const PositionedDirectional(top: 12, start: 12,
                        child: Text('WorldVoice • ROOM',
                          style: TextStyle(color: Colors.white,
                            fontSize: 12, fontWeight: FontWeight.w900))),
                      PositionedDirectional(top: 10, end: 10,
                        child: Text(open ? '● OPEN' : 'ENDED',
                          style: const TextStyle(color: Color(0xFFAAFFDA),
                            fontWeight: FontWeight.bold))),
                    ]),
                  ),
                  Padding(padding: const EdgeInsets.all(13),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white,
                            fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(host, style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        Text(canJoin
                            ? (ar ? 'اضغط لدخول الروم' : 'Tap to join room')
                            : (ar ? 'الروم غير متاح' : 'Room unavailable'),
                          style: const TextStyle(color: Color(0xFF8EEDC1),
                            fontSize: 12)),
                      ]),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StoryCard extends StatefulWidget {
  const _StoryCard({required this.id});
  final String id;
  @override
  State<_StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<_StoryCard> {
  final StoryService _service = StoryService();
  late final Future<StoryItem?> _story = _getStory();

  Future<StoryItem?> _getStory() async {
    // The service returns only stories this user is authorized to see.
    final feed = await _service.fetchFeed();
    for (final item in feed) {
      if (item.id == widget.id &&
          item.expiresAtMs > DateTime.now().millisecondsSinceEpoch) {
        return item;
      }
    }
    return null;
  }

  Future<void> _view(StoryItem story) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => StoryViewerScreen(
        stories: [story], service: _service,
        isArabic: Localizations.localeOf(context).languageCode == 'ar',
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return FutureBuilder<StoryItem?>(
      future: _story,
      builder: (context, snapshot) {
        final story = snapshot.data;
        final showImage = story != null && !story.isVideo &&
            Uri.tryParse(story.mediaUrl)?.scheme == 'https';
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 290),
          child: Material(
            color: const Color(0xFF303148),
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: story == null ? null : () => _view(story),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 178,
                    child: Stack(fit: StackFit.expand, children: [
                      if (showImage)
                        Image.network(story.mediaUrl, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const ColoredBox(color: Color(0xFF41345B)))
                      else
                        const ColoredBox(color: Color(0xFF41345B)),
                      if (story?.isVideo == true)
                        const Center(child: Icon(Icons.play_circle_rounded,
                          size: 62, color: Colors.white)),
                      const PositionedDirectional(top: 12, start: 12,
                        child: Text('WorldVoice • STORY',
                          style: TextStyle(color: Colors.white,
                            fontSize: 12, fontWeight: FontWeight.w900))),
                    ]),
                  ),
                  Padding(padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(story?.ownerName ?? 'WorldVoice',
                          style: const TextStyle(color: Colors.white,
                            fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(story == null
                          ? (ar ? 'الستوري غير متاحة أو انتهت' : 'Story expired or unavailable')
                          : (ar ? 'اضغط لمشاهدة الستوري' : 'Tap to view story'),
                          style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                      ]),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
