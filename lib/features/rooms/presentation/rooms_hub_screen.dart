import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/localization/locale_controller.dart';
import '../../live/presentation/live_screen.dart';
import '../../learn/presentation/learn_screen.dart';
import '../services/room_teacher_ai_service.dart';
import '../services/agora_voice_room_controller.dart';
import '../data/room_mode.dart';
import 'agora_voice_room_screen.dart';
import 'room_teacher_ai_sheet.dart';
import 'voice_rooms_list.dart';

class RoomsHubScreen extends StatefulWidget {
  const RoomsHubScreen({
    required this.localeController,
    super.key,
  });

  final LocaleController localeController;

  @override
  State<RoomsHubScreen> createState() => _RoomsHubScreenState();
}

class _RoomsHubScreenState extends State<RoomsHubScreen> {
  int _section = 0;
  bool _searchOpen = false;
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.localeController.locale?.languageCode ?? 'en';
    final rtl = const {'ar', 'ur', 'fa'}.contains(code);
    final labels = _RoomsHubLabels(code);

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      labels.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => setState(() {
                      _searchOpen = !_searchOpen;
                      if (!_searchOpen) _search.clear();
                    }),
                    tooltip: labels.search,
                    icon: Icon(_searchOpen
                        ? Icons.close_rounded
                        : Icons.search_rounded),
                  ),
                ],
              ),
            ),
            if (_searchOpen)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: labels.search,
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            SizedBox(
              height: 50,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                scrollDirection: Axis.horizontal,
                itemCount: labels.sections.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = _section == index;
                  return ChoiceChip(
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _section = index),
                    avatar: Icon(
                      _sectionIcon(index),
                      size: 18,
                    ),
                    label: Text(labels.sections[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _section == 0
                  ? VoiceRoomsList(
                      languageCode: code,
                      searchQuery: _search.text,
                      localeController: widget.localeController,
                    )
                  : _section == 1
                      ? LiveScreen(localeController: widget.localeController)
                      : _section == 2
                          ? _TeacherAiHub(languageCode: code, searchQuery: _search.text, localeController: widget.localeController)
                          : LearnScreen(localeController: widget.localeController),
            ),
          ],
        ),
      ),
    );
  }

  IconData _sectionIcon(int index) {
    switch (index) {
      case 0:
        return Icons.mic_rounded;
      case 1:
        return Icons.live_tv_rounded;
      case 2:
        return Icons.auto_awesome_rounded;
      default:
        return Icons.school_rounded;
    }
  }
}

class _RoomsHubLabels {
  _RoomsHubLabels(String code)
      : title = 'Rooms',
        search = code == 'ar'
            ? 'بحث'
            : code == 'es'
                ? 'Buscar'
                : 'Search',
        sections = code == 'ar'
            ? const [
                'الغرف الصوتية',
                'البث المباشر',
                'أستاذ AI',
                'أتعلم',
              ]
            : code == 'es'
                ? const [
                    'Salas de voz',
                    'Live',
                    'Teacher AI',
                    'Aprender',
                  ]
                : const [
                    'Voice Rooms',
                    'Live',
                    'Teacher AI',
                    'Learn',
                  ];

  final String title;
  final String search;
  final List<String> sections;
}


/// Teacher AI is room-bound: use the real room membership and backend rather
/// than inventing a separate AI session or displaying a dead tab.
class _TeacherAiHub extends StatelessWidget {
  const _TeacherAiHub({required this.languageCode, required this.searchQuery, required this.localeController});

  final String languageCode;
  final String searchQuery;
  final LocaleController localeController;

  bool get _ar => languageCode == 'ar';

  Future<void> _openRecentRoom(BuildContext context, String roomId, String language) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
      final room = await roomRef.get();
      final participant = await roomRef.collection('participants').doc(user.uid).get();
      if (!context.mounted) return;
      if (room.data()?['isOpen'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_ar ? 'الغرفة مغلقة. اختر غرفة مفتوحة من الأسفل.'
              : 'That room is closed. Pick an open room below.'),
        ));
        return;
      }
      final roomData = room.data() ?? const <String, dynamic>{};
      if (!participant.exists) {
        if (roomData['isPrivate'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_ar ? 'ادخل الغرفة الخاصة باستخدام الكود أولاً.'
                : 'Join that private room with its access code first.'),
          ));
          return;
        }
        await Navigator.of(context).push<void>(MaterialPageRoute(
          builder: (_) => AgoraVoiceRoomScreen(
            channelId: roomId,
            roomName: (roomData['name'] ?? 'WorldVoice Room').toString(),
            roomLanguageCode:
                (roomData['languageCode'] ?? languageCode).toString(),
            initialShowTeacherAiSeat: roomData['showTeacherAiSeat'] == true,
            initialMode: RoomMode.values.firstWhere(
              (mode) => mode.name == roomData['mode']?.toString(),
              orElse: () => RoomMode.chat,
            ),
            initialRole: AgoraRoomRole.listener,
            openTeacherAiOnJoin: true,
            localeController: localeController,
          ),
        ));
        return;
      }

      final service = RoomTeacherAiService(roomId: roomId);
      if (!service.isAskConfigured) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_ar ? 'خدمة Teacher AI تحتاج ربط الخادم أولاً.'
              : 'The Teacher AI backend must be configured first.'),
        ));
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => RoomTeacherAiSheet(
          service: service,
          roomLanguageCode: language.isNotEmpty ? language : languageCode,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_ar ? 'تعذر فتح الغرفة. جرّب الدخول إليها من القائمة.'
            : 'Could not open that room. Try joining it from the list.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
          child: Text(
            _ar
                ? 'أستاذ AI مرتبط بالغرف الصوتية. اختر غرفة وسيفتح بعد دخولك.'
                : 'Teacher AI works inside voice rooms. Pick a room below and AI opens after joining.',
          ),
        ),
        if (user != null)
          SizedBox(
            height: 122,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('room_history')
                  .orderBy('lastEnteredAt', descending: true)
                  .limit(6)
                  .snapshots(),
              builder: (context, snapshot) {
                final rooms = snapshot.data?.docs;
                if (snapshot.hasError) {
                  return Center(child: Text(_ar
                      ? 'تعذر تحميل الغرف الأخيرة.'
                      : 'Could not load recent rooms.'));
                }
                if (rooms == null || rooms.isEmpty) {
                  return Center(child: Text(_ar
                      ? 'ادخل غرفة من الأسفل لاستخدام أستاذ AI.'
                      : 'Join a room below to start using Teacher AI.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  scrollDirection: Axis.horizontal,
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final data = room.data();
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ActionChip(
                        avatar: const Icon(Icons.smart_toy_outlined, size: 18),
                        label: Text((data['roomName'] ?? room.id).toString()),
                        onPressed: () => _openRecentRoom(
                          context,
                          room.id,
                          (data['roomLanguageCode'] ?? languageCode).toString(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        Expanded(
          child: VoiceRoomsList(
            languageCode: languageCode,
            searchQuery: searchQuery,
            openTeacherAiOnJoin: true,
            localeController: localeController,
          ),
        ),
      ],
    );
  }
}
