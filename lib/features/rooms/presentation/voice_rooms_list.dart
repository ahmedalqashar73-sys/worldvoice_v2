import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/agora_config.dart';
import '../services/agora_voice_room_controller.dart';
import 'agora_voice_room_screen.dart';

class VoiceRoomsList extends StatelessWidget {
  const VoiceRoomsList({
    required this.languageCode,
    super.key,
  });

  final String languageCode;

  static const String _temporaryChannel = 'worldvoice_english_lounge';

  bool get _usesTemporaryToken =>
      AgoraConfig.tempToken.trim().isNotEmpty &&
      AgoraConfig.tokenEndpoint.trim().isEmpty;

  Stream<QuerySnapshot<Map<String, dynamic>>> _roomsStream() {
    return FirebaseFirestore.instance
        .collection('rooms')
        .where('isOpen', isEqualTo: true)
        .snapshots();
  }

  Future<void> _createRoom(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_usesTemporaryToken) {
      final existing = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(_temporaryChannel)
          .get();

      if (existing.exists && existing.data()?['isOpen'] == true) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'There is already an active room. Open it from the room list.',
            ),
          ),
        );
        return;
      }
    }

    final controller = TextEditingController();
    final roomName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(languageCode == 'ar' ? 'إنشاء غرفة' : 'Create room'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: InputDecoration(
            hintText: languageCode == 'ar' ? 'اسم الغرفة' : 'Room name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(languageCode == 'ar' ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: Text(languageCode == 'ar' ? 'إنشاء' : 'Create'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (roomName == null || !context.mounted) return;

    final channelId = _usesTemporaryToken
        ? _temporaryChannel
        : 'wv_${user.uid.substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}';

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AgoraVoiceRoomScreen(
          channelId: channelId,
          roomName: roomName,
          initialRole: AgoraRoomRole.speaker,
        ),
      ),
    );
  }

  void _joinRoom(
    BuildContext context, {
    required String channelId,
    required String roomName,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AgoraVoiceRoomScreen(
          channelId: channelId,
          roomName: roomName,
          initialRole: AgoraRoomRole.listener,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _roomsStream(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];

        return Stack(
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (docs.isEmpty)
              _EmptyRooms(languageCode: languageCode)
            else
              ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 96),
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final name =
                      (data['name'] ?? 'WorldVoice Room').toString();
                  final hostName =
                      (data['hostName'] ?? 'WorldVoice host').toString();
                  final roomLanguage =
                      (data['languageCode'] ?? 'en').toString();
                  final hostPhotoUrl =
                      (data['hostPhotoUrl'] as String?)?.trim();

                  return _RoomCard(
                    name: name,
                    hostName: hostName,
                    languageCode: roomLanguage,
                    hostPhotoUrl: hostPhotoUrl,
                    onTap: () => _joinRoom(
                      context,
                      channelId: doc.id,
                      roomName: name,
                    ),
                  );
                },
              ),
            PositionedDirectional(
              end: 18,
              bottom: 18,
              child: FloatingActionButton.extended(
                heroTag: 'create_voice_room',
                onPressed: () => _createRoom(context),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  languageCode == 'ar' ? 'إنشاء غرفة' : 'Create room',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyRooms extends StatelessWidget {
  const _EmptyRooms({required this.languageCode});

  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.graphic_eq_rounded, size: 54),
            const SizedBox(height: 12),
            Text(
              languageCode == 'ar'
                  ? 'لا توجد غرف مفتوحة الآن'
                  : 'No rooms are open right now',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              languageCode == 'ar'
                  ? 'أنشئ غرفة وادعُ أصحابك للدخول.'
                  : 'Create a room and invite your friends to join.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.name,
    required this.hostName,
    required this.languageCode,
    required this.hostPhotoUrl,
    required this.onTap,
  });

  final String name;
  final String hostName;
  final String languageCode;
  final String? hostPhotoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: hostPhotoUrl?.isNotEmpty == true
                    ? NetworkImage(hostPhotoUrl!)
                    : null,
                child: hostPhotoUrl?.isNotEmpty == true
                    ? null
                    : const Icon(Icons.mic_rounded),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            languageCode.toUpperCase(),
                            style: TextStyle(
                              color: colors.onPrimaryContainer,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 16),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            hostName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    const Row(
                      children: [
                        _LivePulse(),
                        SizedBox(width: 7),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePulse extends StatefulWidget {
  const _LivePulse();

  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
      lowerBound: .6,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}
