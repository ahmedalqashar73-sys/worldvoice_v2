import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import '../services/worldvoice_notification_service.dart';
import '../../live/presentation/live_screen.dart';
import '../../rooms/data/room_mode.dart';
import '../../rooms/presentation/agora_voice_room_screen.dart';
import '../../rooms/services/agora_voice_room_controller.dart';

/// Official, read-only activity conversation. Data is created by the backend
/// for followed hosts only, never by another chat user.
class WorldVoiceActivityScreen extends StatelessWidget {
  const WorldVoiceActivityScreen({super.key, required this.localeController});
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final ar = localeController.locale?.languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF2196F3),
            child: Icon(Icons.mic_rounded, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(ar ? 'غرف البث المباشر والصوت'
              : 'Voice Rooms & Live', maxLines: 1,
              overflow: TextOverflow.ellipsis)),
          const Icon(Icons.verified, color: Color(0xFF0CBA86), size: 18),
        ]),
        actions: [
          IconButton(
            tooltip: ar ? 'إعدادات إشعارات الغرف' : 'Activity notification settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => showModalBottomSheet<void>(
              context: context, showDragHandle: true,
              builder: (_) => _ActivityPreferences(ar: ar),
            ),
          ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Sign in required'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid)
                  .collection('activity_inbox')
                  .orderBy('createdAt', descending: true).limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(ar
                      ? 'تعذر تحميل إشعارات الغرف. تحقق من قواعد Firebase.'
                      : 'Could not load activity. Check Firebase rules.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final events = snapshot.data!.docs;
                if (events.isEmpty) {
                  return Center(child: Text(ar
                      ? 'ستظهر هنا الغرف واللايف للأشخاص الذين تتابعهم.'
                      : 'Rooms and live streams from people you follow appear here.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (context, index) => _ActivityCard(
                    key: ValueKey(events[index].id),
                    data: events[index].data(), ar: ar,
                    localeController: localeController,
                  ),
                );
              },
            ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    super.key, required this.data, required this.ar,
    required this.localeController,
  });
  final Map<String, dynamic> data;
  final bool ar;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final kind = data['kind'] == 'live' ? 'live' : 'room';
    final live = kind == 'live';
    final sessionId = (data['sessionId'] ?? '').toString();
    final name = (data['hostName'] ?? 'WorldVoice').toString();
    final avatar = (data['hostPhotoUrl'] ?? '').toString();
    final sessionRef = FirebaseFirestore.instance
        .collection(live ? 'live_sessions' : 'rooms').doc(sessionId);
    final createdAt = data['createdAt'];
    final clock = createdAt is Timestamp
        ? TimeOfDay.fromDateTime(createdAt.toDate()).format(context) : '';
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: sessionRef.snapshots(),
      builder: (context, snap) {
        final actual = snap.data?.data();
        final active = actual != null &&
            (live ? actual['isLive'] == true : actual['isOpen'] == true);
        final title = (actual?['name'] ?? actual?['topic'] ??
            data['title'] ?? name).toString();
        final language = (actual?['languageCode'] ??
            data['languageCode'] ?? 'en').toString().toUpperCase();
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(alignment: AlignmentDirectional.centerEnd,
                    child: Text(clock, style: Theme.of(context).textTheme.labelSmall)),
                  const SizedBox(height: 9),
                  Text(
                    !active
                        ? (ar ? (live ? 'لقد انتهى هذا البث المباشر'
                            : 'لقد انتهت هذه الغرفة الصوتية')
                            : (live ? 'This live stream has ended'
                            : 'This voice room has ended'))
                        : (ar ? (live ? 'بدأ المضيف الذي تتابعه بثًا مباشرًا'
                            : 'بدأ المضيف الذي تتابعه غرفة صوتية مباشرة')
                            : (live ? 'Someone you follow went live'
                            : 'Someone you follow started a voice room')),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(colors: active
                          ? [const Color(0xFF302266), const Color(0xFF47337E)]
                          : [const Color(0xFF545454), const Color(0xFF626262)]),
                    ),
                    padding: const EdgeInsets.all(15),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          if (active) ...[
                            const Icon(Icons.graphic_eq_rounded,
                                size: 17, color: Colors.white),
                            const Spacer(),
                          ],
                          DecoratedBox(decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(9)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 5),
                              child: Text(language, style:
                                const TextStyle(color: Colors.white)),
                            )),
                        ]),
                        const SizedBox(height: 13),
                        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white,
                            fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 18),
                        Row(children: [
                          CircleAvatar(radius: 24,
                            foregroundImage: avatar.startsWith('https://')
                                ? NetworkImage(avatar) : null,
                            child: avatar.startsWith('https://') ? null
                                : const Icon(Icons.person_outline)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(name, maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w700))),
                          if (!active)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(color: Colors.black38,
                                borderRadius: BorderRadius.circular(7)),
                              child: const Text('Ended',
                                style: TextStyle(color: Colors.white)),
                            ),
                        ]),
                        if (!live && active) ...[
                          const SizedBox(height: 12),
                          _RoomParticipantPreview(sessionId: sessionId),
                        ],
                      ]),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: active ? () async {
                      final latest = await sessionRef.get();
                      if (!context.mounted) return;
                      final current = latest.data();
                      final stillOpen = current != null &&
                          (live ? current['isLive'] == true :
                              current['isOpen'] == true);
                      if (!stillOpen) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ar ? 'انتهت الجلسة' : 'Session ended')));
                        return;
                      }
                      if (live) {
                        await LiveScreen.openLiveById(
                          context, sessionId, localeController);
                      } else {
                        await Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => AgoraVoiceRoomScreen(
                            channelId: sessionId,
                            roomName: (current['name'] ?? title).toString(),
                            initialRole: AgoraRoomRole.listener,
                            roomLanguageCode:
                              (current['languageCode'] ?? 'en').toString(),
                            initialMode: RoomMode.values.firstWhere(
                              (mode) => mode.name == current['mode']?.toString(),
                              orElse: () => RoomMode.chat),
                            initialShowTeacherAiSeat:
                              current['showTeacherAiSeat'] == true,
                            initialVipOnly: current['vipOnly'] == true,
                            localeController: localeController,
                          ),
                        ));
                      }
                    } : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 13),
                      child: Row(children: [
                        Expanded(child: Text(active
                            ? (ar ? (live ? 'شاهد البث المباشر'
                                : 'شاهد غرفة الصوت')
                              : (live ? 'Watch live' : 'Join voice room'))
                            : (ar ? 'انتهى النشاط' : 'Activity ended'),
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                        const Icon(Icons.chevron_right),
                      ]),
                    ),
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

class _RoomParticipantPreview extends StatelessWidget {
  const _RoomParticipantPreview({required this.sessionId});
  final String sessionId;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('rooms').doc(sessionId)
          .collection('participants').limit(5).snapshots(),
      builder: (context, snapshot) {
        final people = snapshot.data?.docs ?? [];
        if (people.isEmpty) return const SizedBox.shrink();
        return Row(children: [
          for (final person in people)
            Padding(padding: const EdgeInsetsDirectional.only(end: 5),
              child: CircleAvatar(radius: 14,
                foregroundImage: (person.data()['photoUrl'] ?? '')
                        .toString().startsWith('https://')
                  ? NetworkImage(person.data()['photoUrl'].toString()) : null,
                child: (person.data()['photoUrl'] ?? '').toString()
                        .startsWith('https://') ? null
                    : const Icon(Icons.person, size: 12)),
            ),
          Text('${people.length}+',
              style: const TextStyle(color: Colors.white70)),
        ]);
      },
    );
  }
}

class _ActivityPreferences extends StatefulWidget {
  const _ActivityPreferences({required this.ar});
  final bool ar;
  @override
  State<_ActivityPreferences> createState() => _ActivityPreferencesState();
}

class _ActivityPreferencesState extends State<_ActivityPreferences> {
  bool? _rooms;
  bool? _lives;
  bool _busy = false;

  Future<void> _save() async {
    if (_busy || _rooms == null || _lives == null) return;
    setState(() => _busy = true);
    try {
      await WorldVoiceNotificationService.post(
        '/system/activity/preferences',
        {'rooms': _rooms, 'lives': _lives},
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: uid == null ? const Stream.empty() :
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        _rooms ??= data['roomNotificationsEnabled'] != false;
        _lives ??= data['liveNotificationsEnabled'] != false;
        return SafeArea(child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.ar ? 'إشعارات الأصدقاء' : 'Followed host notifications',
              style: Theme.of(context).textTheme.titleLarge),
            SwitchListTile.adaptive(
              title: Text(widget.ar ? 'عندما يفتح شخص أتابعه غرفة صوتية'
                : 'When someone I follow starts a room'),
              value: _rooms!,
              onChanged: _busy ? null : (v) {
                setState(() => _rooms = v);
                _save();
              },
            ),
            SwitchListTile.adaptive(
              title: Text(widget.ar ? 'عندما يبدأ شخص أتابعه بثًا مباشرًا'
                : 'When someone I follow goes live'),
              value: _lives!,
              onChanged: _busy ? null : (v) {
                setState(() => _lives = v);
                _save();
              },
            ),
          ]),
        ));
      },
    );
  }
}
