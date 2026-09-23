import 'dart:async';

import 'package:flutter/material.dart';

import '../data/room_moderation_models.dart';
import '../data/room_stage_models.dart';
import '../services/agora_voice_room_controller.dart';
import '../services/room_moderation_service.dart';
import 'room_stage_grid.dart';

class AgoraVoiceRoomScreen extends StatefulWidget {
  const AgoraVoiceRoomScreen({
    required this.channelId,
    required this.roomName,
    required this.initialRole,
    this.roomLanguageCode,
    this.initialShowTeacherAiSeat = false,
    super.key,
  });

  final String channelId;
  final String roomName;
  final AgoraRoomRole initialRole;
  final String? roomLanguageCode;
  final bool initialShowTeacherAiSeat;

  @override
  State<AgoraVoiceRoomScreen> createState() => _AgoraVoiceRoomScreenState();
}

class _AgoraVoiceRoomScreenState extends State<AgoraVoiceRoomScreen> {
  late final AgoraVoiceRoomController _controller;
  late final RoomModerationService _moderation;

  StreamSubscription<List<RoomParticipant>>? _participantsSub;
  StreamSubscription<RoomParticipant?>? _meSub;
  StreamSubscription<bool>? _roomOpenSub;
  StreamSubscription<bool>? _teacherAiSeatSub;

  List<RoomParticipant> _participants = const <RoomParticipant>[];
  RoomParticipant? _me;
  int? _lastSyncedAgoraUid;
  late bool _showTeacherAiSeat;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _showTeacherAiSeat = widget.initialShowTeacherAiSeat;
    _controller = AgoraVoiceRoomController()..addListener(_refresh);
    _moderation = RoomModerationService(
      channelId: widget.channelId,
      roomName: widget.roomName,
      roomLanguageCode: widget.roomLanguageCode,
      initialShowTeacherAiSeat: widget.initialShowTeacherAiSeat,
    );
    unawaited(_startRoomSession());
  }

  Future<void> _startRoomSession() async {
    try {
      await _moderation.enter(
        asHost: widget.initialRole == AgoraRoomRole.speaker,
      );

      _roomOpenSub = _moderation.watchRoomOpen().listen((isOpen) {
        if (!isOpen && !_leaving) {
          unawaited(_exitClosedRoom());
        }
      });

      _teacherAiSeatSub =
          _moderation.watchTeacherAiSeatVisible().listen((isVisible) {
        if (!mounted) return;
        setState(() => _showTeacherAiSeat = isVisible);
      });

      _participantsSub =
          _moderation.watchParticipants().listen((participants) {
        if (!mounted) return;
        setState(() => _participants = participants);
      });

      _meSub = _moderation.watchMe().listen(_handleMyParticipant);

      await _controller.connect(
        channelId: widget.channelId,
        role: widget.initialRole,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      await _moderation.leave();
      await _controller.leave();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _exitClosedRoom() async {
    if (_leaving) return;
    _leaving = true;

    await _controller.leave();
    await _moderation.leave();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('The room has ended.')),
    );
    Navigator.of(context).pop();
  }

  void _handleMyParticipant(RoomParticipant? participant) {
    if (!mounted) return;
    setState(() => _me = participant);

    if (participant == null || !_controller.joined) return;

    final desiredAgoraRole = participant.isOnStage
        ? AgoraRoomRole.speaker
        : AgoraRoomRole.listener;

    if (_controller.role != desiredAgoraRole) {
      unawaited(_controller.switchRole(desiredAgoraRole));
    }
  }

  void _refresh() {
    final agoraUid = _controller.localUid;
    if (_controller.joined &&
        agoraUid != null &&
        agoraUid != _lastSyncedAgoraUid) {
      _lastSyncedAgoraUid = agoraUid;
      unawaited(_moderation.syncAgoraUid(agoraUid));
    }

    final participant = _me;
    if (_controller.joined && participant != null) {
      final desiredAgoraRole = participant.isOnStage
          ? AgoraRoomRole.speaker
          : AgoraRoomRole.listener;
      if (_controller.role != desiredAgoraRole) {
        unawaited(_controller.switchRole(desiredAgoraRole));
      }
    }

    if (mounted) setState(() {});
  }

  bool get _isHost =>
      _me?.role == RoomMemberRole.host ||
      (_me == null && widget.initialRole == AgoraRoomRole.speaker);

  bool get _handRaised => _me?.handRaised == true;

  List<RoomParticipant> get _raisedHands => _participants
      .where(
        (participant) =>
            participant.role == RoomMemberRole.listener &&
            participant.handRaised,
      )
      .toList(growable: false);

  List<RoomParticipant> get _listeners => _participants
      .where((participant) => participant.role == RoomMemberRole.listener)
      .toList(growable: false);

  Set<int> get _occupiedSeatIndexes => _participants
      .where((participant) => participant.isOnStage)
      .map((participant) => participant.seatIndex)
      .whereType<int>()
      .where((index) => index >= 1 && index <= 8)
      .toSet();

  int? get _firstFreeSeat {
    final occupied = _occupiedSeatIndexes;
    for (var index = 1; index <= 8; index++) {
      if (!occupied.contains(index)) return index;
    }
    return null;
  }

  List<RoomSeatState> _buildSeats() {
    final seats = List<RoomSeatState>.generate(
      8,
      (index) => RoomSeatState(
        index: index + 1,
        role: RoomMemberRole.speaker,
      ),
    );

    for (final participant in _participants) {
      if (!participant.isOnStage) continue;
      final seatIndex = participant.seatIndex;
      if (seatIndex == null || seatIndex < 1 || seatIndex > 8) continue;

      seats[seatIndex - 1] = RoomSeatState(
        index: seatIndex,
        role: participant.role,
        userId: participant.userId,
        displayName: participant.displayName,
        avatarUrl: participant.photoUrl,
        agoraUid: participant.agoraUid,
        isMuted: participant.userId == _moderation.currentUserId
            ? _controller.muted
            : false,
        isLocalUser: participant.userId == _moderation.currentUserId,
      );
    }

    if (_participants.isEmpty &&
        widget.initialRole == AgoraRoomRole.speaker) {
      seats[0] = RoomSeatState(
        index: 1,
        role: RoomMemberRole.host,
        userId: _moderation.currentUserId,
        displayName: 'You',
        agoraUid: _controller.localUid,
        isMuted: _controller.muted,
        isLocalUser: true,
      );
    }

    return seats;
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;

    try {
      await _moderation.leave();
      await _controller.leave();
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _acceptHand(RoomParticipant participant) async {
    final seatIndex = _firstFreeSeat;
    if (seatIndex == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All 8 speaker seats are occupied.')),
      );
      return;
    }

    await _moderation.assignSeat(
      userId: participant.userId,
      role: RoomMemberRole.speaker,
      seatIndex: seatIndex,
    );
  }

  void _handleSeatTap(RoomSeatState seat) {
    if (!_isHost) {
      if (_me?.role == RoomMemberRole.listener && seat.isEmpty) {
        unawaited(_requestSeat());
      }
      return;
    }

    if (seat.isEmpty) {
      _showInviteListenerSheet(seat.index);
      return;
    }

    if (seat.role == RoomMemberRole.host) return;

    RoomParticipant? participant;
    for (final item in _participants) {
      if (item.userId == seat.userId) {
        participant = item;
        break;
      }
    }
    if (participant == null) return;

    _showStageMemberActions(participant);
  }

  Future<void> _requestSeat() async {
    if (_handRaised) return;
    await _moderation.setHandRaised(true);
    if (!mounted) return;

    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'تم إرسال طلب الصعود للهوست.'
              : 'Your seat request was sent to the host.',
        ),
      ),
    );
  }

  Future<void> _showRoomControls() async {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  widget.roomName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  isArabic ? 'أدوات الغرفة' : 'Room tools',
                ),
              ),
              if (_isHost)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.smart_toy_rounded),
                  title: const Text('Teacher AI'),
                  subtitle: Text(
                    isArabic
                        ? 'إظهار أو إخفاء مقعد Teacher AI خارج المقاعد الثمانية.'
                        : 'Show or hide the Teacher AI seat outside the 8 seats.',
                  ),
                  value: _showTeacherAiSeat,
                  onChanged: (value) async {
                    await _moderation.setTeacherAiSeatVisible(value);
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                  },
                ),
              const Divider(),
              _RoomToolTile(
                icon: Icons.wallpaper_rounded,
                label: isArabic ? 'الخلفية' : 'Background',
              ),
              _RoomToolTile(
                icon: Icons.draw_rounded,
                label: isArabic ? 'السبورة' : 'Board',
              ),
              _RoomToolTile(
                icon: Icons.music_note_rounded,
                label: isArabic ? 'الموسيقى' : 'Music',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showInviteListenerSheet(int seatIndex) async {
    final listeners = _listeners;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: listeners.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No listeners are available to invite right now.',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  const ListTile(
                    title: Text(
                      'Invite listener',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text('Choose who should take this seat.'),
                  ),
                  for (final participant in listeners)
                    ListTile(
                      leading: _ParticipantAvatar(participant: participant),
                      title: Text(participant.displayName),
                      trailing:
                          const Icon(Icons.chevron_right_rounded, size: 18),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _showRolePicker(
                          participant: participant,
                          seatIndex: seatIndex,
                        );
                      },
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _showRolePicker({
    required RoomParticipant participant,
    required int seatIndex,
  }) async {
    final selectedRole = await showModalBottomSheet<RoomMemberRole>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                participant.displayName,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text('Seat $seatIndex'),
            ),
            _RoleOption(
              icon: Icons.mic_rounded,
              label: 'Speaker',
              onTap: () =>
                  Navigator.pop(sheetContext, RoomMemberRole.speaker),
            ),
            _RoleOption(
              icon: Icons.group_work_rounded,
              label: 'Co-host',
              onTap: () =>
                  Navigator.pop(sheetContext, RoomMemberRole.coHost),
            ),
            _RoleOption(
              icon: Icons.workspace_premium_rounded,
              label: 'VIP seat',
              onTap: () =>
                  Navigator.pop(sheetContext, RoomMemberRole.vipSeat),
            ),
          ],
        ),
      ),
    );

    if (selectedRole == null) return;

    await _moderation.assignSeat(
      userId: participant.userId,
      role: selectedRole,
      seatIndex: seatIndex,
    );
  }

  Future<void> _showStageMemberActions(
    RoomParticipant participant,
  ) async {
    final action = await showModalBottomSheet<_StageAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: _ParticipantAvatar(participant: participant),
              title: Text(
                participant.displayName,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(participant.role.label),
            ),
            _RoleOption(
              icon: Icons.mic_rounded,
              label: 'Set as Speaker',
              onTap: () =>
                  Navigator.pop(sheetContext, _StageAction.speaker),
            ),
            _RoleOption(
              icon: Icons.group_work_rounded,
              label: 'Set as Co-host',
              onTap: () =>
                  Navigator.pop(sheetContext, _StageAction.coHost),
            ),
            _RoleOption(
              icon: Icons.workspace_premium_rounded,
              label: 'Set as VIP seat',
              onTap: () =>
                  Navigator.pop(sheetContext, _StageAction.vipSeat),
            ),
            _RoleOption(
              icon: Icons.keyboard_arrow_down_rounded,
              label: 'Move to listeners',
              onTap: () =>
                  Navigator.pop(sheetContext, _StageAction.listener),
            ),
          ],
        ),
      ),
    );

    if (action == null) return;

    switch (action) {
      case _StageAction.speaker:
        await _moderation.changeStageRole(
          userId: participant.userId,
          role: RoomMemberRole.speaker,
        );
        break;
      case _StageAction.coHost:
        await _moderation.changeStageRole(
          userId: participant.userId,
          role: RoomMemberRole.coHost,
        );
        break;
      case _StageAction.vipSeat:
        await _moderation.changeStageRole(
          userId: participant.userId,
          role: RoomMemberRole.vipSeat,
        );
        break;
      case _StageAction.listener:
        await _moderation.moveToListener(participant.userId);
        break;
    }
  }

  @override
  void dispose() {
    _participantsSub?.cancel();
    _meSub?.cancel();
    _roomOpenSub?.cancel();
    _teacherAiSeatSub?.cancel();
    _controller.removeListener(_refresh);
    unawaited(_moderation.leave());
    unawaited(_controller.leave());
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isPublishing = _controller.role == AgoraRoomRole.speaker;
    final myRole = _me?.role ??
        (widget.initialRole == AgoraRoomRole.speaker
            ? RoomMemberRole.host
            : RoomMemberRole.listener);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _leave,
          icon: const Icon(Icons.close_rounded),
        ),
        title: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _showRoomControls,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        widget.roomName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more_rounded, size: 20),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _controller.joined
                            ? Colors.green
                            : colors.outline,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_participants.length} members • LIVE',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_controller.connecting)
              const LinearProgressIndicator(minHeight: 2),
            if (_controller.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Card(
                  color: colors.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: colors.onErrorContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _controller.error!,
                            style: TextStyle(color: colors.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Stage',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                      if (_isHost && _raisedHands.isNotEmpty)
                        Badge(
                          label: Text('${_raisedHands.length}'),
                          child: const Icon(Icons.pan_tool_rounded),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RoomStageGrid(
                    seats: _buildSeats(),
                    onSeatTap: _handleSeatTap,
                  ),
                  if (_showTeacherAiSeat) ...[
                    const SizedBox(height: 12),
                    const _TeacherAiSeatCompact(),
                  ],
                  const SizedBox(height: 14),
                  if (_isHost && _raisedHands.isNotEmpty)
                    _RaisedHandsCard(
                      requests: _raisedHands,
                      onAccept: _acceptHand,
                      onReject: (participant) =>
                          _moderation.rejectHand(participant.userId),
                    ),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        myRole == RoomMemberRole.listener
                            ? Icons.headphones_rounded
                            : Icons.mic_rounded,
                      ),
                      title: Text(
                        myRole.label,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        myRole == RoomMemberRole.listener
                            ? _handRaised
                                ? 'Hand raised — waiting for host approval.'
                                : 'You are listening to the room.'
                            : 'You are on the stage.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  top: BorderSide(color: colors.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  if (isPublishing)
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _controller.joined
                            ? () => _controller.setMuted(!_controller.muted)
                            : null,
                        icon: Icon(
                          _controller.muted
                              ? Icons.mic_off_rounded
                              : Icons.mic_rounded,
                        ),
                        label: Text(
                          _controller.muted ? 'Unmute' : 'Mute',
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _controller.joined
                            ? () => _handRaised
                                ? _moderation.setHandRaised(false)
                                : _requestSeat()
                            : null,
                        icon: Icon(
                          _handRaised
                              ? Icons.pan_tool_rounded
                              : Icons.pan_tool_alt_rounded,
                        ),
                        label: Text(
                          _handRaised ? 'Cancel hand' : 'Raise hand',
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _leave,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.error,
                      foregroundColor: colors.onError,
                    ),
                    child: const Icon(Icons.call_end_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _StageAction {
  speaker,
  coHost,
  vipSeat,
  listener,
}

class _RaisedHandsCard extends StatelessWidget {
  const _RaisedHandsCard({
    required this.requests,
    required this.onAccept,
    required this.onReject,
  });

  final List<RoomParticipant> requests;
  final ValueChanged<RoomParticipant> onAccept;
  final ValueChanged<RoomParticipant> onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.pan_tool_rounded),
        title: Text(
          'Raised hands (${requests.length})',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        children: [
          for (final participant in requests)
            ListTile(
              leading: _ParticipantAvatar(participant: participant),
              title: Text(participant.displayName),
              trailing: Wrap(
                spacing: 6,
                children: [
                  IconButton(
                    tooltip: 'Reject',
                    onPressed: () => onReject(participant),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  IconButton.filled(
                    tooltip: 'Accept',
                    onPressed: () => onAccept(participant),
                    icon: const Icon(Icons.check_rounded),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  const _ParticipantAvatar({required this.participant});

  final RoomParticipant participant;

  @override
  Widget build(BuildContext context) {
    final photoUrl = participant.photoUrl;
    return CircleAvatar(
      backgroundImage:
          photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
      child: photoUrl?.isNotEmpty == true
          ? null
          : const Icon(Icons.person_rounded),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}

