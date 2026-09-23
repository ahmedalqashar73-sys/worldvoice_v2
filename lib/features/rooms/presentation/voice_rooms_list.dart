import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';


import '../../profile/data/profile_identity_utils.dart';
import '../data/agora_config.dart';
import '../services/agora_voice_room_controller.dart';
import '../services/room_history_service.dart';
import 'agora_voice_room_screen.dart';

class VoiceRoomsList extends StatefulWidget {
  const VoiceRoomsList({
    required this.languageCode,
    this.localeController,
    super.key,
  });

  final String languageCode;
  final LocaleController? localeController;

  @override
  State<VoiceRoomsList> createState() => _VoiceRoomsListState();
}

class _VoiceRoomsListState extends State<VoiceRoomsList> {
  static const String _temporaryChannel = 'worldvoice_english_lounge';

  String? _selectedLanguage;
  Future<_RoomLanguagePrefs>? _prefsFuture;

  bool get _usesTemporaryToken =>
      AgoraConfig.tempToken.trim().isNotEmpty &&
      AgoraConfig.tokenEndpoint.trim().isEmpty;

  bool get _isArabic => widget.languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _prefsFuture = _loadLanguagePrefs();
  }

  Future<_RoomLanguagePrefs> _loadLanguagePrefs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const _RoomLanguagePrefs(
        nativeLanguage: 'en',
        learningLanguages: <String>[],
        giftLevel: 0,
      );
    }

    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = profile.data() ?? const <String, dynamic>{};
    final native =
        (data['nativeLanguageCode'] ?? 'en').toString().trim().toLowerCase();
    final learning = (data['learningLanguageCodes'] as List?)
            ?.map((value) => value.toString().trim().toLowerCase())
            .where((value) => value.isNotEmpty)
            .toList() ??
        const <String>[];

    return _RoomLanguagePrefs(
      nativeLanguage: native.isEmpty ? 'en' : native,
      learningLanguages: learning,
      giftLevel: (data['giftLevel'] as num?)?.toInt() ?? 0,
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _roomsStream() {
    return FirebaseFirestore.instance
        .collection('rooms')
        .where('isOpen', isEqualTo: true)
        .snapshots();
  }

  Future<void> _createRoom(
    BuildContext context,
    _RoomLanguagePrefs prefs,
  ) async {
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
          SnackBar(
            content: Text(
              _isArabic
                  ? 'هناك غرفة مفتوحة الآن. ادخل عليها من القائمة.'
                  : 'There is already an active room. Open it from the list.',
            ),
          ),
        );
        return;
      }
    }

    if (!context.mounted) return;

    final initialLanguage = _selectedLanguage == null ||
            _selectedLanguage == 'all'
        ? prefs.nativeLanguage
        : _selectedLanguage!;

    final result = await showDialog<_CreateRoomResult>(
      context: context,
      builder: (dialogContext) => _CreateRoomDialog(
        isArabic: _isArabic,
        languageOptions: prefs.roomLanguages,
        initialLanguage: initialLanguage,
        giftLevel: prefs.giftLevel,
      ),
    );

    if (result == null || !context.mounted) return;

    final privateCode = result.isPrivate ? _makePrivateCode() : null;

    final safeUid =
        user.uid.length >= 8 ? user.uid.substring(0, 8) : user.uid;
    final channelId = _usesTemporaryToken
        ? _temporaryChannel
        : 'wv_${safeUid}_${DateTime.now().millisecondsSinceEpoch}';

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AgoraVoiceRoomScreen(
          localeController: widget.localeController,
          channelId: channelId,
          roomName: result.name,
          roomLanguageCode: result.languageCode,
          initialShowTeacherAiSeat: result.showTeacherAiSeat,
          initialIsPrivate: result.isPrivate,
          initialVipOnly: result.vipOnly,
          privateAccessCode: privateCode,
          initialRole: AgoraRoomRole.speaker,
        ),
      ),
    );
  }

  void _joinRoom(
    BuildContext context, {
    required String channelId,
    required String roomName,
    required String roomLanguageCode,
    required bool showTeacherAiSeat,
    bool isPrivate = false,
    bool vipOnly = false,
    String? privateAccessCode,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AgoraVoiceRoomScreen(
          localeController: widget.localeController,
          channelId: channelId,
          roomName: roomName,
          roomLanguageCode: roomLanguageCode,
          initialShowTeacherAiSeat: showTeacherAiSeat,
          initialIsPrivate: isPrivate,
          initialVipOnly: vipOnly,
          privateAccessCode: privateAccessCode,
          initialRole: AgoraRoomRole.listener,
        ),
      ),
    );
  }

  String _makePrivateCode() {
    final raw = DateTime.now().microsecondsSinceEpoch
        .toRadixString(36)
        .toUpperCase();
    return raw.length <= 6 ? raw : raw.substring(raw.length - 6);
  }

  Future<void> _joinPrivateRoom(BuildContext context) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_isArabic ? 'دخول غرفة خاصة' : 'Join private room'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: _isArabic ? 'كود الغرفة' : 'Room code',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_isArabic ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim().toUpperCase();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: Text(_isArabic ? 'دخول' : 'Join'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (code == null || !context.mounted) return;

    try {
      final codeDoc = await FirebaseFirestore.instance
          .collection('private_room_codes')
          .doc(code)
          .get();
      final roomId = codeDoc.data()?['roomId']?.toString();
      if (!codeDoc.exists || roomId == null || roomId.isEmpty) {
        throw StateError(
          _isArabic ? 'كود الغرفة غير صحيح.' : 'Invalid room code.',
        );
      }

      final roomDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .get();
      final data = roomDoc.data();
      if (!roomDoc.exists || data?['isOpen'] != true) {
        throw StateError(
          _isArabic ? 'الغرفة غير متاحة الآن.' : 'The room is not open.',
        );
      }

      if (!context.mounted) return;
      _joinRoom(
        context,
        channelId: roomId,
        roomName: (data?['name'] ?? 'WorldVoice Room').toString(),
        roomLanguageCode: (data?['languageCode'] ?? 'en').toString(),
        showTeacherAiSeat: data?['showTeacherAiSeat'] == true,
        isPrivate: true,
        vipOnly: data?['vipOnly'] == true,
        privateAccessCode: code,
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _showHistory(BuildContext context) async {
    final history = RoomHistoryService();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * .72,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: Text(
                _isArabic ? 'سجل الغرف' : 'Room history',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              trailing: IconButton(
                onPressed: () => Navigator.pop(sheetContext),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: history.watchHistory(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ??
                      const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        _isArabic
                            ? 'لا يوجد سجل غرف بعد.'
                            : 'No room history yet.',
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: docs.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final raw = data['lastEnteredAt'];
                      final enteredAt =
                          raw is Timestamp ? raw.toDate() : null;
                      final visits =
                          (data['visitCount'] as num?)?.toInt() ?? 1;

                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.mic_rounded),
                        ),
                        title: Text(
                          (data['roomName'] ?? 'WorldVoice Room').toString(),
                        ),
                        subtitle: Text(
                          enteredAt == null
                              ? '$visits visit(s)'
                              : '$visits visit(s) • '
                                  '${enteredAt.year}-'
                                  '${enteredAt.month.toString().padLeft(2, '0')}-'
                                  '${enteredAt.day.toString().padLeft(2, '0')}',
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RoomLanguagePrefs>(
      future: _prefsFuture,
      builder: (context, prefsSnapshot) {
        if (!prefsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final prefs = prefsSnapshot.data!;
        final tabs = prefs.filterLanguages;
        final selected = _selectedLanguage ?? tabs.first;

        return Column(
          children: [
            const _RoomPromotionBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showHistory(context),
                    icon: const Icon(Icons.history_rounded),
                    label: Text(
                      _isArabic ? 'السجل' : 'History',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _joinPrivateRoom(context),
                    icon: const Icon(Icons.lock_outline_rounded),
                    label: Text(
                      _isArabic ? 'دخول بكود' : 'Join by code',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final code = tabs[index];
                  final isAll = code == 'all';
                  return ChoiceChip(
                    selected: selected == code,
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() => _selectedLanguage = code);
                    },
                    label: Text(
                      isAll
                          ? (_isArabic ? 'الكل' : 'All')
                          : _languageLabel(code),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _roomsStream(),
                builder: (context, snapshot) {
                  final allDocs = snapshot.data?.docs ??
                      const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                  final publicDocs = allDocs
                      .where((doc) => doc.data()['isPrivate'] != true)
                      .toList(growable: false);
                  final docs = selected == 'all'
                      ? publicDocs
                      : publicDocs
                          .where(
                            (doc) =>
                                (doc.data()['languageCode'] ?? 'en')
                                    .toString()
                                    .toLowerCase() ==
                                selected,
                          )
                          .toList(growable: false);

                  return Stack(
                    children: [
                      if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                          !snapshot.hasData)
                        const Center(child: CircularProgressIndicator())
                      else if (docs.isEmpty)
                        _EmptyRooms(
                          isArabic: _isArabic,
                          languageCode: selected,
                        )
                      else
                        ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(18, 14, 18, 96),
                          itemCount: docs.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data();
                            final name =
                                (data['name'] ?? 'WorldVoice Room').toString();
                            final hostName = (data['hostName'] ??
                                    (_isArabic
                                        ? 'مضيف WorldVoice'
                                        : 'WorldVoice host'))
                                .toString();
                            final roomLanguage =
                                (data['languageCode'] ?? 'en')
                                    .toString()
                                    .toLowerCase();
                            final hostPhotoUrl =
                                (data['hostPhotoUrl'] as String?)?.trim();
                            final hostCountry =
                                (data['hostCountry'] ?? '').toString();
                            final showTeacherAiSeat =
                                data['showTeacherAiSeat'] == true;
                            final vipOnly = data['vipOnly'] == true;

                            return _RoomCard(
                              channelId: doc.id,
                              name: name,
                              hostName: hostName,
                              hostPhotoUrl: hostPhotoUrl,
                              hostCountry: hostCountry,
                              languageCode: roomLanguage,
                              vipOnly: vipOnly,
                              onTap: () => _joinRoom(
                                context,
                                channelId: doc.id,
                                roomName: name,
                                roomLanguageCode: roomLanguage,
                                showTeacherAiSeat: showTeacherAiSeat,
                                vipOnly: vipOnly,
                              ),
                            );
                          },
                        ),
                      PositionedDirectional(
                        end: 18,
                        bottom: 18,
                        child: FloatingActionButton.extended(
                          heroTag: 'create_voice_room',
                          onPressed: () => _createRoom(context, prefs),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(
                            _isArabic ? 'إنشاء غرفة' : 'Create room',
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RoomPromotionBanner extends StatelessWidget {
  const _RoomPromotionBanner();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('room_promotions')
          .doc('current')
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        if (data == null || data['enabled'] != true) {
          return const SizedBox.shrink();
        }

        final title = (data['title'] ?? '').toString().trim();
        final subtitle = (data['subtitle'] ?? '').toString().trim();
        final imageUrl = (data['imageUrl'] ?? '').toString().trim();

        if (title.isEmpty && subtitle.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(18, 8, 18, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF5C46E8), Color(0xFF16A978)],
            ),
            image: imageUrl.isEmpty
                ? null
                : DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                    opacity: .22,
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CreateRoomDialog extends StatefulWidget {
  const _CreateRoomDialog({
    required this.isArabic,
    required this.languageOptions,
    required this.initialLanguage,
    required this.giftLevel,
  });

  final bool isArabic;
  final List<String> languageOptions;
  final String initialLanguage;
  final int giftLevel;

  @override
  State<_CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<_CreateRoomDialog> {
  final TextEditingController _nameController = TextEditingController();
  late String _language;
  bool _showTeacherAiSeat = false;
  bool _isPrivate = false;
  bool _vipOnly = false;

  @override
  void initState() {
    super.initState();
    _language = widget.languageOptions.contains(widget.initialLanguage)
        ? widget.initialLanguage
        : widget.languageOptions.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isArabic ? 'إنشاء غرفة صوتية' : 'Create voice room'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            maxLength: 40,
            decoration: InputDecoration(
              labelText: widget.isArabic ? 'اسم الغرفة' : 'Room name',
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _language,
            decoration: InputDecoration(
              labelText: widget.isArabic ? 'لغة الغرفة' : 'Room language',
            ),
            items: [
              for (final code in widget.languageOptions)
                DropdownMenuItem(
                  value: code,
                  child: Text(_languageLabel(code)),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _language = value);
            },
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.smart_toy_rounded),
            title: Text(
              widget.isArabic ? 'إظهار Teacher AI' : 'Show Teacher AI',
            ),
            subtitle: Text(
              widget.isArabic
                  ? 'يمكنك تغييره لاحقًا من إعدادات الغرفة.'
                  : 'You can change this later from room settings.',
            ),
            value: _showTeacherAiSeat,
            onChanged: (value) {
              setState(() => _showTeacherAiSeat = value);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.lock_rounded),
            title: Text(
              widget.isArabic ? 'غرفة خاصة' : 'Private room',
            ),
            subtitle: Text(
              widget.giftLevel >= 14
                  ? (widget.isArabic
                      ? 'الدخول يكون بكود خاص.'
                      : 'Members join using a private code.')
                  : (widget.isArabic
                      ? 'تتطلب Gift Level 14.'
                      : 'Requires Gift Level 14.'),
            ),
            value: _isPrivate,
            onChanged: widget.giftLevel >= 14
                ? (value) => setState(() => _isPrivate = value)
                : null,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.workspace_premium_rounded),
            title: Text(
              widget.isArabic ? 'VIP فقط' : 'VIP only',
            ),
            value: _vipOnly,
            onChanged: (value) => setState(() => _vipOnly = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.isArabic ? 'إلغاء' : 'Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(
              context,
              _CreateRoomResult(
                name: name,
                languageCode: _language,
                showTeacherAiSeat: _showTeacherAiSeat,
                isPrivate: _isPrivate,
                vipOnly: _vipOnly,
              ),
            );
          },
          child: Text(widget.isArabic ? 'إنشاء' : 'Create'),
        ),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.channelId,
    required this.name,
    required this.hostName,
    required this.hostPhotoUrl,
    required this.hostCountry,
    required this.languageCode,
    required this.vipOnly,
    required this.onTap,
  });

  final String channelId;
  final String name;
  final String hostName;
  final String? hostPhotoUrl;
  final String hostCountry;
  final String languageCode;
  final bool vipOnly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(channelId)
          .collection('participants')
          .snapshots(),
      builder: (context, snapshot) {
        final participants = snapshot.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final preview = participants.take(3).toList(growable: false);

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AvatarStack(
                    hostPhotoUrl: hostPhotoUrl,
                    participants: preview,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _SmallBadge(
                              text: '🎙 Voice',
                              background: colors.primaryContainer,
                              foreground: colors.onPrimaryContainer,
                            ),
                            _SmallBadge(
                              text: _languageLabel(languageCode),
                              background: colors.secondaryContainer,
                              foreground: colors.onSecondaryContainer,
                            ),
                            if (vipOnly)
                              _SmallBadge(
                                text: 'VIP',
                                background: const Color(0xFFFFD978),
                                foreground: const Color(0xFF5E4300),
                              ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Text(
                              profileCountryFlag(hostCountry),
                              style: const TextStyle(fontSize: 17),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                hostName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            const _LivePulse(),
                            const SizedBox(width: 7),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Icon(Icons.people_alt_rounded, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${participants.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({
    required this.hostPhotoUrl,
    required this.participants,
  });

  final String? hostPhotoUrl;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> participants;

  @override
  Widget build(BuildContext context) {
    final urls = <String>[];
    if (hostPhotoUrl?.isNotEmpty == true) urls.add(hostPhotoUrl!);

    for (final participant in participants) {
      final value = (participant.data()['photoUrl'] as String?)?.trim();
      if (value != null && value.isNotEmpty && !urls.contains(value)) {
        urls.add(value);
      }
      if (urls.length >= 3) break;
    }

    if (urls.isEmpty) {
      return CircleAvatar(
        radius: 29,
        backgroundColor:
            Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.record_voice_over_rounded),
      );
    }

    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        children: [
          for (var index = 0; index < urls.length; index++)
            Positioned(
              left: index * 14,
              top: index * 7,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(urls[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyRooms extends StatelessWidget {
  const _EmptyRooms({
    required this.isArabic,
    required this.languageCode,
  });

  final bool isArabic;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final languageText =
        languageCode == 'all' ? '' : ' ${_languageLabel(languageCode)}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.graphic_eq_rounded, size: 54),
            const SizedBox(height: 12),
            Text(
              isArabic
                  ? 'لا توجد غرف مفتوحة الآن'
                  : 'No$languageText rooms are open right now',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isArabic
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

class _RoomLanguagePrefs {
  const _RoomLanguagePrefs({
    required this.nativeLanguage,
    required this.learningLanguages,
    required this.giftLevel,
  });

  final String nativeLanguage;
  final List<String> learningLanguages;
  final int giftLevel;

  List<String> get roomLanguages {
    final result = <String>[];
    if (nativeLanguage.isNotEmpty) result.add(nativeLanguage);
    for (final code in learningLanguages) {
      if (code.isNotEmpty && !result.contains(code)) result.add(code);
    }
    if (result.isEmpty) result.add('en');
    return result;
  }

  List<String> get filterLanguages => <String>[
        ...roomLanguages,
        'all',
      ];
}

class _CreateRoomResult {
  const _CreateRoomResult({
    required this.name,
    required this.languageCode,
    required this.showTeacherAiSeat,
    required this.isPrivate,
    required this.vipOnly,
  });

  final String name;
  final String languageCode;
  final bool showTeacherAiSeat;
  final bool isPrivate;
  final bool vipOnly;
}

String _languageLabel(String code) {
  const names = <String, String>{
    'ar': 'العربية',
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'pt': 'Português',
    'tr': 'Türkçe',
    'ru': 'Русский',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
    'ur': 'اردو',
    'fa': 'فارسی',
    'id': 'Indonesia',
    'th': 'ไทย',
    'hi': 'हिन्दी',
  };

  return names[code.toLowerCase()] ?? code.toUpperCase();
}
