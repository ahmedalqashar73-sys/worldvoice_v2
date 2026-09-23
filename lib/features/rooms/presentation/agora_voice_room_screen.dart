import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:just_audio/just_audio.dart';

import '../../home/presentation/home_screen.dart';
import '../../profile/presentation/public_profile_screen.dart';
import '../../../core/localization/locale_controller.dart';
import '../data/room_feature_models.dart';
import '../data/room_moderation_models.dart';
import '../data/room_stage_models.dart';
import '../services/agora_voice_room_controller.dart';
import '../services/room_feature_service.dart';
import '../services/room_history_service.dart';
import '../services/room_moderation_service.dart';
import '../services/room_quota_service.dart';
import 'room_board_screen.dart';
import 'room_chat_sheet.dart';
import 'room_music_sheet.dart';
import 'room_quiz_sheet.dart';
import 'room_extras_sheet.dart';
import 'room_members_sheet.dart';
import 'room_mod_log_sheet.dart';
import 'room_stage_grid.dart';

class AgoraVoiceRoomScreen extends StatefulWidget {
  const AgoraVoiceRoomScreen({
    required this.channelId,
    required this.roomName,
    required this.initialRole,
    this.localeController,
    this.roomLanguageCode,
    this.initialShowTeacherAiSeat = false,
    this.initialIsPrivate = false,
    this.initialVipOnly = false,
    this.privateAccessCode,
    super.key,
  });

  final String channelId;
  final String roomName;
  final AgoraRoomRole initialRole;
  final LocaleController? localeController;
  final String? roomLanguageCode;
  final bool initialShowTeacherAiSeat;
  final bool initialIsPrivate;
  final bool initialVipOnly;
  final String? privateAccessCode;

  @override
  State<AgoraVoiceRoomScreen> createState() => _AgoraVoiceRoomScreenState();
}

class _AgoraVoiceRoomScreenState extends State<AgoraVoiceRoomScreen> {
  late final AgoraVoiceRoomController _controller;
  late final RoomModerationService _moderation;
  late final RoomHistoryService _history;
  late final RoomQuotaService _quota;
  late final RoomFeatureService _features;
  late final AudioPlayer _musicPlayer;
  String? _loadedMusicUrl;

  StreamSubscription<List<RoomParticipant>>? _participantsSub;
  StreamSubscription<RoomParticipant?>? _meSub;
  StreamSubscription<bool>? _roomOpenSub;
  StreamSubscription<bool>? _teacherAiSeatSub;
  StreamSubscription<RoomFeatureState>? _featuresSub;
  StreamSubscription<List<RoomGiftEvent>>? _giftSub;

  List<RoomParticipant> _participants = const <RoomParticipant>[];
  RoomParticipant? _me;
  int? _lastSyncedAgoraUid;
  late bool _showTeacherAiSeat;
  bool _leaving = false;
  bool _participantWasReady = false;
  bool _trackingEnded = false;
  bool _minimized = false;
  String? _lastGiftId;
  bool _giftStreamPrimed = false;
  OverlayEntry? _giftOverlay;
  Timer? _giftOverlayTimer;
  Timer? _speakingTimer;

  RoomFeatureState _featureState = const RoomFeatureState(
    roomLevel: 1,
    roomXp: 0,
    themeId: 'royalPurple',
    boardWriteEnabled: true,
    isPrivate: false,
    vipOnly: false,
    musicPlaying: false,
    screenShareActive: false,
  );

  @override
  void initState() {
    super.initState();
    _showTeacherAiSeat = widget.initialShowTeacherAiSeat;
    _controller = AgoraVoiceRoomController()..addListener(_refresh);
    _history = RoomHistoryService();
    _quota = RoomQuotaService();
    _features = RoomFeatureService(roomId: widget.channelId);
    _musicPlayer = AudioPlayer();
    _moderation = RoomModerationService(
      channelId: widget.channelId,
      roomName: widget.roomName,
      roomLanguageCode: widget.roomLanguageCode,
      initialShowTeacherAiSeat: widget.initialShowTeacherAiSeat,
      initialIsPrivate: widget.initialIsPrivate,
      initialVipOnly: widget.initialVipOnly,
      privateAccessCode: widget.privateAccessCode,
    );
    _speakingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        final me = _me;
        if (!_controller.joined ||
            me == null ||
            !me.isOnStage ||
            _controller.muted ||
            me.forcedMuted) {
          return;
        }

        if (_controller.activeSpeakerUid == _controller.localUid) {
          unawaited(_moderation.addSpeakingSeconds(10));
        }
      },
    );
    unawaited(_startRoomSession());
  }

  Future<void> _startRoomSession() async {
    try {
      final asHost = widget.initialRole == AgoraRoomRole.speaker;
      final level = await _moderation.roomLevel();
      final quotaStatus = await _quota.startSession(
        asHost: asHost,
        roomLevel: level,
      );

      if (!quotaStatus.allowed) {
        if (!mounted) return;
        _leaving = true;
        final isArabic =
            Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'انتهى وقت الغرف المتاح لك اليوم.'
                  : 'Your room time for today has been used.',
            ),
          ),
        );
        Navigator.of(context).pop();
        return;
      }

      await _moderation.enter(
        asHost: asHost,
      );

      await _history.recordEnter(
        roomId: widget.channelId,
        roomName: widget.roomName,
        languageCode: widget.roomLanguageCode,
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

      _featuresSub = _features.watchState().listen((state) {
        if (!mounted) return;
        setState(() => _featureState = state);
        unawaited(_syncRoomMusic(state));
      });

      _giftSub = _features.watchGifts().listen((gifts) {
        if (!mounted || gifts.isEmpty) return;
        final latest = gifts.first;

        if (!_giftStreamPrimed) {
          _giftStreamPrimed = true;
          _lastGiftId = latest.id;
          return;
        }

        if (latest.id == _lastGiftId) return;
        _lastGiftId = latest.id;
        _showGiftOverlay(latest);
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

  void _showGiftOverlay(RoomGiftEvent gift) {
    if (!mounted) return;

    _giftOverlayTimer?.cancel();
    _speakingTimer?.cancel();
    _giftOverlay?.remove();

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => _RoomGiftOverlay(event: gift),
    );
    _giftOverlay = entry;
    overlay.insert(entry);

    _giftOverlayTimer = Timer(
      Duration(seconds: gift.giftId == 'dragon' ? 5 : 3),
      () {
        if (_giftOverlay == entry) {
          entry.remove();
          _giftOverlay = null;
        }
      },
    );
  }

  Future<void> _syncRoomMusic(RoomFeatureState state) async {
    final url = state.musicUrl?.trim();
    if (url == null || url.isEmpty) {
      if (_musicPlayer.playing) await _musicPlayer.pause();
      _loadedMusicUrl = null;
      return;
    }

    try {
      if (_loadedMusicUrl != url) {
        await _musicPlayer.setUrl(url);
        _loadedMusicUrl = url;
      }
      if (state.musicPlaying) {
        if (!_musicPlayer.playing) await _musicPlayer.play();
      } else if (_musicPlayer.playing) {
        await _musicPlayer.pause();
      }
    } catch (_) {
      // Keep Agora room audio alive even if a shared music URL fails.
    }
  }

  Future<void> _finishSessionTracking() async {
    if (_trackingEnded) return;
    _trackingEnded = true;
    await _quota.endSession();
    await _history.recordLeave(widget.channelId);
  }

  Future<void> _exitClosedRoom() async {
    if (_leaving) return;
    _leaving = true;

    await _finishSessionTracking();
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

    if (participant == null) {
      if (_participantWasReady && !_leaving) {
        unawaited(_exitRemovedFromRoom());
      }
      return;
    }

    _participantWasReady = true;
    setState(() => _me = participant);

    if (!_controller.joined) return;

    final desiredAgoraRole = participant.isOnStage
        ? AgoraRoomRole.speaker
        : AgoraRoomRole.listener;

    if (_controller.role != desiredAgoraRole) {
      unawaited(_controller.switchRole(desiredAgoraRole));
    }

    if (participant.forcedMuted &&
        desiredAgoraRole == AgoraRoomRole.speaker &&
        !_controller.muted) {
      unawaited(_controller.setMuted(true));
    }
  }

  Future<void> _exitRemovedFromRoom() async {
    if (_leaving) return;
    _leaving = true;
    await _finishSessionTracking();
    await _controller.leave();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You were removed from the room.')),
    );
    Navigator.of(context).pop();
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

  bool get _isModerator => _me?.isModerator == true;

  bool get _canModerate => _isHost || _isModerator;

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
            : participant.forcedMuted,
        isActiveSpeaker: participant.agoraUid != null &&
            participant.agoraUid == _controller.activeSpeakerUid,
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
      await _finishSessionTracking();
      await _moderation.leave();
      await _controller.leave();
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _acceptHand(RoomParticipant participant) async {
    final requested = participant.requestedSeatIndex;
    final seatIndex = requested != null &&
            requested >= 1 &&
            requested <= 8 &&
            !_occupiedSeatIndexes.contains(requested)
        ? requested
        : _firstFreeSeat;

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
    if (seat.role == RoomMemberRole.teacherAi) return;

    if (seat.isEmpty) {
      if (_isHost) {
        _showInviteListenerSheet(seat.index);
      } else if (_me?.role == RoomMemberRole.listener) {
        unawaited(_requestSeat(seat.index));
      }
      return;
    }

    final userId = seat.userId;
    if (userId == null || userId.isEmpty) return;
    _openParticipantProfile(userId);
  }

  void _handleSeatLongPress(RoomSeatState seat) {
    if (!_canModerate || seat.isEmpty) return;
    final userId = seat.userId;
    if (userId == null || userId.isEmpty) return;

    RoomParticipant? participant;
    for (final item in _participants) {
      if (item.userId == userId) {
        participant = item;
        break;
      }
    }
    if (participant == null ||
        participant.role == RoomMemberRole.host) {
      return;
    }

    _showStageMemberActions(participant);
  }

  void _openParticipantProfile(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          userId: userId,
          languageCode:
              Localizations.localeOf(context).languageCode.toLowerCase(),
        ),
      ),
    );
  }

  Future<void> _requestSeat([int? seatIndex]) async {
    await _moderation.setHandRaised(
      true,
      requestedSeatIndex: seatIndex,
    );
    if (!mounted) return;

    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final seatText = seatIndex == null
        ? ''
        : (isArabic ? ' للمقعد $seatIndex' : ' for seat $seatIndex');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'تم إرسال طلب الصعود$seatText للهوست.'
              : 'Your request$seatText was sent to the host.',
        ),
      ),
    );
  }

  Future<void> _showRaisedHandsSheet() async {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            ListTile(
              leading: const Icon(Icons.pan_tool_alt_rounded),
              title: Text(
                isArabic ? 'طلبات رفع اليد' : 'Raise hand requests',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                isArabic
                    ? '${_raisedHands.length} طلب'
                    : '${_raisedHands.length} request(s)',
              ),
            ),
            for (final participant in _raisedHands)
              ListTile(
                leading: _ParticipantAvatar(participant: participant),
                title: Text(participant.displayName),
                subtitle: participant.requestedSeatIndex == null
                    ? Text(isArabic ? 'يريد الصعود' : 'Wants to speak')
                    : Text(
                        isArabic
                            ? 'طلب المقعد ${participant.requestedSeatIndex}'
                            : 'Requested seat ${participant.requestedSeatIndex}',
                      ),
                trailing: Wrap(
                  spacing: 6,
                  children: [
                    IconButton(
                      tooltip: isArabic ? 'رفض' : 'Reject',
                      onPressed: () async {
                        await _moderation.rejectHand(participant.userId);
                        if (sheetContext.mounted &&
                            _raisedHands.length <= 1) {
                          Navigator.pop(sheetContext);
                        }
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                    IconButton.filled(
                      tooltip: isArabic ? 'موافقة' : 'Accept',
                      onPressed: () async {
                        await _acceptHand(participant);
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                      icon: const Icon(Icons.check_rounded),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRoomChat() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RoomChatSheet(
        roomId: widget.channelId,
        canModerate: _canModerate,
      ),
    );
  }

  Future<void> _showBoard() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoomBoardScreen(
          roomId: widget.channelId,
          canWrite: _isHost || _featureState.boardWriteEnabled,
          isHost: _isHost,
          agoraController: _controller,
        ),
      ),
    );
  }

  Future<void> _showMusic() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RoomMusicSheet(
        roomId: widget.channelId,
        isHost: _isHost,
      ),
    );
  }

  Future<void> _showQuiz() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RoomQuizSheet(
        roomId: widget.channelId,
        isHost: _isHost,
      ),
    );
  }

  Future<void> _shareRoom() async {
    final language = widget.roomLanguageCode?.toUpperCase() ?? '';
    await SharePlus.instance.share(
      ShareParams(
        text: 'WorldVoice • ${widget.roomName}'
            '${language.isEmpty ? '' : ' • $language'}'
            '\nRoom ID: ${widget.channelId}',
      ),
    );
  }

  Future<void> _showRoomExtras() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RoomExtrasSheet(
        roomId: widget.channelId,
        participants: _participants,
        isHost: _isHost,
        showTeacherAiSeat: _showTeacherAiSeat,
      ),
    );
  }

  Future<void> _showMembers() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RoomMembersSheet(
        roomId: widget.channelId,
        participants: _participants,
        isHost: _isHost,
        isModerator: _isModerator,
      ),
    );
  }

  Future<void> _showModLog() async {
    if (!_canModerate) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RoomModLogSheet(roomId: widget.channelId),
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
              if (_isHost)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.edit_rounded),
                  title: Text(
                    isArabic
                        ? 'السماح للأعضاء بالكتابة والرسم'
                        : 'Allow members to write and draw',
                  ),
                  value: _featureState.boardWriteEnabled,
                  onChanged: (value) async {
                    await _features.setBoardWriteEnabled(value);
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                  },
                ),
              const Divider(),
              _RoomToolTile(
                icon: Icons.groups_rounded,
                label: isArabic ? 'أعضاء الغرفة' : 'Room members',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showMembers();
                },
              ),
              if (_canModerate)
                _RoomToolTile(
                  icon: Icons.receipt_long_rounded,
                  label: isArabic ? 'سجل المودريتور' : 'Moderator log',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showModLog();
                  },
                ),
              _RoomToolTile(
                icon: Icons.chat_bubble_rounded,
                label: isArabic ? 'دردشة الغرفة' : 'Room chat',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showRoomChat();
                },
              ),
              _RoomToolTile(
                icon: Icons.draw_rounded,
                label: isArabic ? 'السبورة' : 'Board',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showBoard();
                },
              ),
              _RoomToolTile(
                icon: Icons.quiz_rounded,
                label: isArabic ? 'الكويز' : 'Quiz',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showQuiz();
                },
              ),
              _RoomToolTile(
                icon: Icons.music_note_rounded,
                label: isArabic ? 'الموسيقى' : 'Music',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showMusic();
                },
              ),
              _RoomToolTile(
                icon: Icons.share_rounded,
                label: isArabic ? 'مشاركة الغرفة' : 'Share room',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _shareRoom();
                },
              ),
              _RoomToolTile(
                icon: Icons.auto_awesome_rounded,
                label: isArabic
                    ? 'الثيم والمهام والهدايا والترتيب'
                    : 'Theme, tasks, gifts & leaderboard',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showRoomExtras();
                },
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
              icon: Icons.person_outline_rounded,
              label: 'View profile',
              onTap: () =>
                  Navigator.pop(sheetContext, _StageAction.profile),
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
      case _StageAction.profile:
        _openParticipantProfile(participant.userId);
        break;
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
    _featuresSub?.cancel();
    _giftSub?.cancel();
    _giftOverlayTimer?.cancel();
    _giftOverlay?.remove();
    _giftOverlay = null;
    _controller.removeListener(_refresh);
    unawaited(_musicPlayer.dispose());
    unawaited(_finishSessionTracking());
    unawaited(_moderation.leave());
    unawaited(_controller.leave());
    _controller.dispose();
    super.dispose();
  }

  List<Color> _roomThemeColors(String themeId) {
    switch (themeId) {
      case 'emerald':
        return const [
          Color(0xFF0D4A38),
          Color(0xFF123A32),
          Color(0xFF111D1A),
        ];
      case 'midnight':
        return const [
          Color(0xFF17223A),
          Color(0xFF111827),
          Color(0xFF090D16),
        ];
      default:
        return const [
          Color(0xFF30216E),
          Color(0xFF21194F),
          Color(0xFF17122F),
        ];
    }
  }

  void _minimizeRoom() {
    if (!mounted || widget.localeController == null) return;
    setState(() => _minimized = true);
  }

  Widget _buildMinimizedRoom(BuildContext context) {
    final localeController = widget.localeController;
    if (localeController == null) {
      _minimized = false;
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        HomeScreen(localeController: localeController),
        PositionedDirectional(
          end: 14,
          bottom: 92,
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(28),
            color: const Color(0xFF241A4B),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => setState(() => _minimized = false),
              child: Container(
                width: 178,
                padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _controller.joined
                            ? const Color(0xFF2BBE78)
                            : Colors.white24,
                      ),
                      child: Icon(
                        _controller.muted
                            ? Icons.mic_off_rounded
                            : Icons.mic_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.roomName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${_participants.length} • LIVE',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Leave',
                      visualDensity: VisualDensity.compact,
                      onPressed: _leave,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_minimized) {
      return _buildMinimizedRoom(context);
    }

    final colors = Theme.of(context).colorScheme;
    final isPublishing = _controller.role == AgoraRoomRole.speaker;
    final myRole = _me?.role ??
        (widget.initialRole == AgoraRoomRole.speaker
            ? RoomMemberRole.host
            : RoomMemberRole.listener);
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFF17122F),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
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
                            ? const Color(0xFF5BFF91)
                            : Colors.white38,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_participants.length} members • LIVE',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (widget.localeController != null)
            IconButton(
              tooltip: isArabic ? 'تصغير الغرفة' : 'Minimize room',
              onPressed: _minimizeRoom,
              icon: const Icon(Icons.picture_in_picture_alt_rounded),
            ),
          IconButton(
            tooltip: isArabic ? 'الأعضاء' : 'Members',
            onPressed: _showMembers,
            icon: Badge(
              label: Text('${_participants.length}'),
              child: const Icon(Icons.groups_rounded),
            ),
          ),
          if (_canModerate)
            IconButton(
              tooltip: isArabic ? 'أدوات الغرفة' : 'Room tools',
              onPressed: _showRoomControls,
              icon: const Icon(Icons.more_horiz_rounded),
            ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _roomThemeColors(_featureState.themeId),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              if (_controller.connecting)
                const LinearProgressIndicator(minHeight: 2),
              if (_controller.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.errorContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: colors.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _controller.error!,
                            style: TextStyle(
                              color: colors.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
                  children: [
                    RoomStageGrid(
                      seats: _buildSeats(),
                      onSeatTap: _handleSeatTap,
                      onSeatLongPress: _handleSeatLongPress,
                    ),
                    if (_showTeacherAiSeat) ...[
                      const SizedBox(height: 8),
                      const _TeacherAiCompactSeat(),
                    ],
                    const SizedBox(height: 12),
                    if (_isHost && _raisedHands.isNotEmpty)
                      _RaisedHandNotice(
                        participant: _raisedHands.first,
                        total: _raisedHands.length,
                        isArabic: isArabic,
                        onTap: _showRaisedHandsSheet,
                        onAccept: () => _acceptHand(_raisedHands.first),
                        onReject: () =>
                            _moderation.rejectHand(_raisedHands.first.userId),
                      ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(minHeight: 180),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .06),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          myRole == RoomMemberRole.listener
                              ? (_handRaised
                                  ? (isArabic
                                      ? 'طلب الصعود مُرسل'
                                      : 'Seat request sent')
                                  : (isArabic
                                      ? 'اضغط مقعدًا فارغًا أو ارفع يدك'
                                      : 'Tap an empty seat or raise your hand'))
                              : (isArabic
                                  ? 'أنت على الستيج'
                                  : 'You are on stage'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .58),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF110E24).withValues(alpha: .96),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: .08),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _RoomBottomAction(
                      icon: Icons.call_end_rounded,
                      background: const Color(0xFFFF9B9B),
                      foreground: const Color(0xFF5B0000),
                      onPressed: _leave,
                    ),
                    const Spacer(),
                    if (isPublishing)
                      _RoomBottomAction(
                        icon: _controller.muted
                            ? Icons.mic_off_rounded
                            : Icons.mic_rounded,
                        label: _me?.forcedMuted == true
                            ? (isArabic ? 'مكتوم من المودريتور' : 'Moderator mute')
                            : _controller.muted
                                ? (isArabic ? 'تشغيل' : 'Unmute')
                                : (isArabic ? 'كتم' : 'Mute'),
                        onPressed: _controller.joined &&
                                _me?.forcedMuted != true
                            ? () => _controller.setMuted(!_controller.muted)
                            : null,
                      )
                    else
                      _RoomBottomAction(
                        icon: _handRaised
                            ? Icons.pan_tool_rounded
                            : Icons.pan_tool_alt_rounded,
                        label: _handRaised
                            ? (isArabic ? 'إلغاء الطلب' : 'Cancel')
                            : (isArabic ? 'رفع اليد' : 'Raise hand'),
                        highlighted: _handRaised,
                        onPressed: _controller.joined
                            ? () => _handRaised
                                ? _moderation.setHandRaised(false)
                                : _requestSeat()
                            : null,
                      ),
                    const SizedBox(width: 8),
                    _RoomBottomAction(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: isArabic ? 'الدردشة' : 'Chat',
                      onPressed: _showRoomChat,
                    ),
                    const SizedBox(width: 8),
                    _RoomBottomAction(
                      icon: Icons.more_horiz_rounded,
                      label: isArabic ? 'المزيد' : 'More',
                      onPressed: _showRoomControls,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomGiftOverlay extends StatelessWidget {
  const _RoomGiftOverlay({required this.event});

  final RoomGiftEvent event;

  @override
  Widget build(BuildContext context) {
    final dragon = event.giftId == 'dragon';

    return IgnorePointer(
      child: Material(
        color: dragon ? Colors.black.withValues(alpha: .34) : Colors.transparent,
        child: SafeArea(
          child: dragon
              ? TweenAnimationBuilder<double>(
                  tween: Tween(begin: -1, end: 1),
                  duration: const Duration(milliseconds: 2200),
                  curve: Curves.easeInOutCubic,
                  builder: (context, value, child) {
                    final width = MediaQuery.sizeOf(context).width;
                    return Stack(
                      children: [
                        Positioned(
                          left: (width * .5) + (value * width * .42) - 70,
                          top: 120 + (40 * (1 - value.abs())),
                          child: Transform.rotate(
                            angle: value * .25,
                            child: const Text(
                              '🐉',
                              style: TextStyle(fontSize: 118),
                            ),
                          ),
                        ),
                        if (value > .35)
                          Positioned(
                            right: 32,
                            top: 250,
                            child: Opacity(
                              opacity: ((value - .35) / .65).clamp(0, 1),
                              child: const Text(
                                '🔥🔥🔥',
                                style: TextStyle(fontSize: 54),
                              ),
                            ),
                          ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 110),
                            child: _GiftCaption(event: event),
                          ),
                        ),
                      ],
                    );
                  },
                )
              : Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 90),
                    child: _GiftCaption(event: event),
                  ),
                ),
        ),
      ),
    );
  }
}

class _GiftCaption extends StatelessWidget {
  const _GiftCaption({required this.event});

  final RoomGiftEvent event;

  @override
  Widget build(BuildContext context) {
    final icon = switch (event.giftId) {
      'dragon' => '🐉',
      'star' => '⭐',
      _ => '🌹',
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF17122F).withValues(alpha: .94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
        boxShadow: const [
          BoxShadow(blurRadius: 22, color: Colors.black45),
        ],
      ),
      child: Text(
        '$icon  ${event.senderName} → ${event.recipientName}  •  ${event.points}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

enum _StageAction {
  profile,
  speaker,
  coHost,
  vipSeat,
  listener,
}

class _RoomToolTile extends StatelessWidget {
  const _RoomToolTile({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap ?? () => Navigator.pop(context),
    );
  }
}

class _RaisedHandNotice extends StatelessWidget {
  const _RaisedHandNotice({
    required this.participant,
    required this.total,
    required this.isArabic,
    required this.onTap,
    required this.onAccept,
    required this.onReject,
  });

  final RoomParticipant participant;
  final int total;
  final bool isArabic;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final seat = participant.requestedSeatIndex;

    return Material(
      color: Colors.black.withValues(alpha: .32),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
          child: Row(
            children: [
              _ParticipantAvatar(participant: participant),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      seat == null
                          ? (isArabic ? 'يريد الصعود' : 'Wants to speak')
                          : (isArabic
                              ? 'يريد المقعد $seat'
                              : 'Wants seat $seat'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (total > 1)
                Container(
                  margin: const EdgeInsetsDirectional.only(end: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6E55FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '+${total - 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              IconButton(
                onPressed: onReject,
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
              ),
              IconButton.filled(
                onPressed: onAccept,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF55DFA0),
                  foregroundColor: const Color(0xFF073B2A),
                ),
                icon: const Icon(Icons.check_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomBottomAction extends StatelessWidget {
  const _RoomBottomAction({
    required this.icon,
    required this.onPressed,
    this.label,
    this.highlighted = false,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final bool highlighted;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final bg = background ??
        (highlighted
            ? const Color(0xFF5B49C9)
            : Colors.white.withValues(alpha: .10));
    final fg = foreground ?? Colors.white;

    if (label == null) {
      return IconButton.filled(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          minimumSize: const Size(48, 48),
        ),
        icon: Icon(icon),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      icon: Icon(icon, size: 19),
      label: Text(label!),
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



class _TeacherAiCompactSeat extends StatelessWidget {
  const _TeacherAiCompactSeat();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF6DE7C0).withValues(alpha: .50),
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: Color(0xFF3A2D71),
              child: Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Teacher AI',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
