import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:just_audio/just_audio.dart';

import '../../home/presentation/home_screen.dart';
import '../../profile/presentation/public_profile_screen.dart';
import '../../../core/localization/locale_controller.dart';
import '../data/room_caption.dart';
import '../data/room_feature_models.dart';
import '../data/room_moderation_models.dart';
import '../data/room_stage_models.dart';
import '../data/room_teacher_ai_note.dart';
import '../services/agora_voice_room_controller.dart';
import '../services/room_caption_service.dart';
import '../services/room_feature_service.dart';
import '../services/room_history_service.dart';
import '../services/room_live_caption_controller.dart';
import '../services/room_moderation_service.dart';
import '../services/room_admin_service.dart';
import '../services/room_quota_service.dart';
import '../services/room_rewarded_ad_service.dart';
import '../services/room_translation_service.dart';
import '../services/room_teacher_ai_service.dart';
import 'room_background_shop_sheet.dart';
import 'room_board_screen.dart';
import '../data/room_mode.dart';
import 'room_chat_sheet.dart';
import 'room_conversation_panel.dart';
import '../services/room_chat_service.dart';
import '../data/room_chat_message.dart';
import 'room_captions_sheet.dart';
import 'room_coin_store_sheet.dart';
import 'room_music_sheet.dart';
import 'room_quiz_sheet.dart';
import 'room_rating_sheet.dart';
import 'room_extras_sheet.dart';
import 'room_gift_overlay.dart';
import 'unified_gift_panel.dart';
import 'room_members_sheet.dart';
import 'room_mod_log_sheet.dart';
import 'room_stage_grid.dart';
import 'room_teacher_ai_sheet.dart';

const MethodChannel _roomTeacherTtsChannel =
    MethodChannel('worldvoice/live_tts');

Future<void> _speakRoomTeacher(
  String text,
  String languageCode,
) async {
  final value = text.trim();
  if (value.isEmpty) return;
  try {
    await _roomTeacherTtsChannel.invokeMethod<void>('speak', {
      'text': value,
      'languageCode': languageCode,
    });
  } on PlatformException {
    // Text remains visible when a device has no matching TTS voice.
  } on MissingPluginException {
    // Older builds keep Teacher AI text even without native speech.
  }
}

Future<void> _stopRoomTeacherVoice() async {
  try {
    await _roomTeacherTtsChannel.invokeMethod<void>('stop');
  } on PlatformException {
    // Best-effort stop.
  } on MissingPluginException {
    // Older builds may not have the channel.
  }
}

class AgoraVoiceRoomScreen extends StatefulWidget {
  const AgoraVoiceRoomScreen({
    required this.channelId,
    required this.roomName,
    required this.initialRole,
    this.localeController,
    this.roomLanguageCode,
    this.initialShowTeacherAiSeat = false,
    this.openTeacherAiOnJoin = false,
    this.initialIsPrivate = false,
    this.initialVipOnly = false,
    this.initialMode = RoomMode.chat,
    this.privateAccessCode,
    super.key,
  });

  final String channelId;
  final String roomName;
  final AgoraRoomRole initialRole;
  final LocaleController? localeController;
  final String? roomLanguageCode;
  final bool initialShowTeacherAiSeat;
  final bool openTeacherAiOnJoin;
  final bool initialIsPrivate;
  final bool initialVipOnly;
  final RoomMode initialMode;
  final String? privateAccessCode;

  @override
  State<AgoraVoiceRoomScreen> createState() => _AgoraVoiceRoomScreenState();
}

class _AgoraVoiceRoomScreenState extends State<AgoraVoiceRoomScreen> {
  late final AgoraVoiceRoomController _controller;
  late final RoomChatService _roomChat;
  Stream<List<RoomChatMessage>>? _chatMessages;
  late final RoomModerationService _moderation;
  late final RoomHistoryService _history;
  late final RoomQuotaService _quota;
  late final RoomRewardedAdService _rewardedAds;
  late final RoomFeatureService _features;
  late final RoomCaptionService _captionService;
  late final RoomLiveCaptionController _captionController;
  late final RoomTranslationService _translationService;
  late final RoomTeacherAiService _teacherAi;
  late final AudioPlayer _musicPlayer;
  String? _loadedMusicUrl;

  StreamSubscription<List<RoomParticipant>>? _participantsSub;
  StreamSubscription<RoomParticipant?>? _meSub;
  StreamSubscription<bool>? _roomOpenSub;
  StreamSubscription<bool>? _teacherAiSeatSub;
  StreamSubscription<RoomFeatureState>? _featuresSub;
  StreamSubscription<List<RoomGiftEvent>>? _giftSub;
  StreamSubscription<List<RoomGiftPreview>>? _freeGiftPreviewSub;
  StreamSubscription<List<RoomChatMessage>>? _freeChatGiftSub;
  StreamSubscription<List<RoomCaption>>? _captionSub;
  StreamSubscription<List<RoomTeacherAiNote>>? _teacherAiSub;
  StreamSubscription<List<RoomTeacherAiSpokenAnswer>>? _teacherAiVoiceSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _stageInviteSub;

  List<RoomParticipant> _participants = const <RoomParticipant>[];
  String? _lastStageInviteSignature;
  RoomParticipant? _me;
  int? _lastSyncedAgoraUid;
  late bool _showTeacherAiSeat;
  bool _leaving = false;
  bool _roleUpdateInProgress = false;
  bool _micBusy = false;
  String? _audioFailure;
  bool _audioRetrying = false;
  bool _participantWasReady = false;
  bool _trackingEnded = false;
  bool _minimized = false;
  String? _lastGiftId;
  bool _giftStreamPrimed = false;
  final DateTime _friendPreviewOpenedAt = DateTime.now();
  final Set<String> _seenFriendPreviewEvents = <String>{};
  OverlayEntry? _giftOverlay;
  Timer? _giftOverlayTimer;
  Timer? _speakingTimer;
  Timer? _quotaTimer;
  bool _quotaEnding = false;
  bool _captionsEnabled = false;
  bool _captionListening = false;
  bool _captionTranslationEnabled = false;
  bool _pronunciationTipsEnabled = false;
  String _captionTargetLanguage = 'en';
  String? _captionError;
  RoomCaption? _latestCaption;
  String? _latestTranslatedCaption;
  String? _lastTranslatedCaptionId;
  String? _lastTeacherAiCaptionId;
  RoomTeacherAiNote? _latestTeacherAiNote;
  bool _teacherAiVoicePrimed = false;
  String? _lastTeacherAiVoiceId;
  bool _teacherAiAutoCaptionPrimed = false;
  String? _lastTeacherAiAutoCaptionId;
  bool _teacherAiAutoReplyBusy = false;
  RoomCaption? _queuedTeacherAiCaption;
  DateTime? _teacherAiSpeechSuppressedUntil;

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
    _roomChat = RoomChatService(roomId: widget.channelId);
    _showTeacherAiSeat = widget.initialShowTeacherAiSeat;
    _controller = AgoraVoiceRoomController()..addListener(_refresh);
    _history = RoomHistoryService();
    _quota = RoomQuotaService();
    _rewardedAds = RoomRewardedAdService();
    _features = RoomFeatureService(roomId: widget.channelId);
    _captionService = RoomCaptionService(roomId: widget.channelId);
    _translationService = RoomTranslationService();
    _teacherAi = RoomTeacherAiService(roomId: widget.channelId);
    _captionTargetLanguage =
        widget.localeController?.locale?.languageCode ?? 'en';
    _captionController = RoomLiveCaptionController(
      service: _captionService,
      onState: ({
        required bool listening,
        String? error,
      }) {
        if (!mounted) return;
        setState(() {
          _captionListening = listening;
          if (error != null && error.trim().isNotEmpty) {
            _captionError = error;
          }
        });
      },
    );
    _musicPlayer = AudioPlayer();
    _moderation = RoomModerationService(
      channelId: widget.channelId,
      roomName: widget.roomName,
      roomLanguageCode: widget.roomLanguageCode,
      initialShowTeacherAiSeat: widget.initialShowTeacherAiSeat,
      initialIsPrivate: widget.initialIsPrivate,
      initialVipOnly: widget.initialVipOnly,
      initialMode: widget.initialMode,
      privateAccessCode: widget.privateAccessCode,
    );
    _speakingTimer = Timer.periodic(
      const Duration(seconds: 30),
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
          unawaited(_features.recordSpeakerActivity(seconds: 30));
        }
      },
    );
    unawaited(_startRoomSession());
  }

  Future<void> _startRoomSession() async {
    var entryStage = 'room-read';
    var membershipEstablished = false;
    try {
      final asHost = widget.initialRole == AgoraRoomRole.speaker;
      final level = await _moderation.roomLevel();
      entryStage = 'quota-check';
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

      _quotaTimer ??= Timer.periodic(
        const Duration(minutes: 1),
        (_) => unawaited(_checkLiveQuota()),
      );

      entryStage = 'room-membership';
      await _moderation.enter(
        asHost: asHost,
      );
      membershipEstablished = true;
      if (mounted) setState(() => _chatMessages = _roomChat.watchMessages());

      // History is optional; a denied history write must not close a room
      // whose membership was successfully established.
      try {
        await _history.recordEnter(
          roomId: widget.channelId,
          roomName: widget.roomName,
          languageCode: widget.roomLanguageCode,
        ).timeout(const Duration(seconds: 8));
      } catch (error) {
        debugPrint('WorldVoice room-history: $error');
        if (mounted) {
          final isArabic = Localizations.localeOf(context).languageCode == 'ar';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isArabic
                ? 'تم الدخول، لكن تعذر حفظ سجل الغرفة.'
                : 'Joined the room, but room history could not be saved.'),
          ));
        }
      }

      _roomOpenSub = _moderation.watchRoomOpen().listen((isOpen) {
        if (!isOpen && !_leaving) {
          unawaited(_exitClosedRoom());
        }
      });

      _teacherAiSeatSub =
          _moderation.watchTeacherAiSeatVisible().listen((isVisible) {
        if (!mounted) return;
        setState(() => _showTeacherAiSeat = isVisible);
        if (!isVisible) {
          _queuedTeacherAiCaption = null;
          unawaited(_stopRoomTeacherVoice());
        }
        unawaited(_syncCaptionPublishing());
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
      }, onError: (Object error, StackTrace stackTrace) {
        // An optional gift stream must not disconnect the voice session.
        debugPrint('WorldVoice gift effects unavailable: $error');
      });

      if (RoomFeatureService.friendPreviewEnabled) {
        _freeGiftPreviewSub = RoomFeatureService.watchFriendGiftPreviews(
          context: widget.initialMode == RoomMode.live ? 'live' : 'room',
          contextId: widget.channelId,
        ).listen((previews) {
          if (!mounted || previews.isEmpty) return;
          final now = DateTime.now();
          RoomGiftPreview? latest;
          for (final event in previews) {
          final sent = event.sentAt;
          // The initial local Firestore write can contain a pending
          // serverTimestamp; don't mark it seen before the real ack.
          if (sent == null) continue;
          final newEvent = _seenFriendPreviewEvents.add(event.eventKey);
          if (!newEvent ||
                sent.isBefore(_friendPreviewOpenedAt.subtract(
                    const Duration(seconds: 1))) ||
                now.difference(sent).inSeconds.abs() > 20) {
              continue;
            }
            latest ??= event;
          }
          if (latest != null) {
            _showGiftOverlay(latest.toVisualEvent(), preview: true);
          }
        }, onError: (Object error, StackTrace stack) {
          // Existing Agora audio always survives missing or older Firebase
          // rules. New preview rule deployment is a separate testing step.
          debugPrint('WorldVoice friend gift demo unavailable: $error');
        });
      }


      if (RoomFeatureService.friendPreviewEnabled) {
        _freeChatGiftSub = _roomChat.watchMessages().listen((messages) {
          if (!mounted) return;
          final now = DateTime.now();
          RoomChatMessage? latest;
          ({String giftId, String recipientId, String nonce})? detail;
          for (final message in messages) {
            final payload = RoomGiftPreviewChatCodec.decode(message.text);
            final timestamp = message.createdAt;
            if (payload == null || timestamp == null ||
                timestamp.isBefore(_friendPreviewOpenedAt.subtract(
                    const Duration(seconds: 1))) ||
                now.difference(timestamp).inSeconds.abs() > 20 ||
                !_seenFriendPreviewEvents.add('chat:${message.id}')) {
              continue;
            }
            latest ??= message;
            detail ??= payload;
          }
          if (latest == null || detail == null) return;
          final recipient = _participants.where(
            (p) => p.userId == detail!.recipientId);
          final sender = _participants.where(
            (p) => p.userId == latest!.userId);
          _showGiftOverlay(RoomGiftEvent(
            id: 'free-chat:${latest.id}',
            senderId: latest.userId,
            senderName: sender.isNotEmpty
                ? sender.first.displayName : latest.displayName,
            recipientId: detail.recipientId,
            recipientName: recipient.isNotEmpty
                ? recipient.first.displayName : 'Friend',
            giftId: detail.giftId,
            points: 0,
            createdAt: latest.createdAt,
          ), preview: true);
        }, onError: (Object error, StackTrace stack) {
          debugPrint('WorldVoice room demo chat transport unavailable: $error');
        });
      }

      // Captions are optional. Missing/out-of-date deployed Firestore rules
      // must not cause an unhandled stream exception or disconnect Agora.
      _captionSub = _captionService.watchLatest().listen(
        _handleCaptions,
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('WorldVoice room captions unavailable: $error');
          if (!mounted || _leaving) return;
          final isArabic =
              Localizations.localeOf(context).languageCode == 'ar';
          setState(() {
            _captionError = isArabic
                ? 'الترجمة المباشرة غير متاحة حاليًا. تحقّق من أذونات الغرفة في Firebase.'
                : 'Live captions are unavailable. Check room permissions in Firebase.';
            _captionsEnabled = false;
          });
          // Other streams, room seats, mic and Agora remain connected.
        },
      );

      _teacherAiSub = _teacherAi.watchNotes().listen((notes) {
        if (!mounted) return;
        setState(() {
          _latestTeacherAiNote = notes.isEmpty ? null : notes.first;
        });
      }, onError: (Object error, StackTrace stackTrace) {
        // Teacher AI is optional and must not break seats, chat or audio.
        debugPrint('WorldVoice Teacher AI notes unavailable: $error');
      });

      _teacherAiVoiceSub =
          _teacherAi.watchSpokenAnswers().listen(_handleTeacherAiVoice,
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('WorldVoice Teacher AI voice unavailable: $error');
        },
      );

      _participantsSub =
          _moderation.watchParticipants().listen((participants) {
        if (!mounted) return;
        setState(() => _participants = participants);
      });

      _meSub = _moderation.watchMe().listen(_handleMyParticipant);
      _stageInviteSub =
          _moderation.watchMyStageInvite().listen(_handleStageInvite);

      entryStage = 'audio-connect';
      // A successful joinChannel() request is not a completed voice
      // connection. Wait for Agora's onJoinChannelSuccess callback.
      try {
        await _controller.ensureConnected(
          channelId: widget.channelId,
          role: widget.initialRole,
        );
        if (mounted) setState(() => _audioFailure = null);
        await _synchronizeParticipantAudio();
      } catch (error) {
        debugPrint('WorldVoice voice join needs attention: $error');
        // A token/network problem must not kick the user out of an otherwise
        // valid Firestore room. Show the exact error and offer a real retry.
        if (mounted && !_leaving) {
          setState(() => _audioFailure = error.toString());
        }
        return;
      }
      if (!mounted || _leaving || !_controller.joined) return;
      // From the hub, open Teacher AI only AFTER actual room membership
      // and the Agora join have completed. Normal room entry is unchanged.
      if (widget.openTeacherAiOnJoin) {
        unawaited(_showTeacherAiChat());
      }
      if (!asHost) return;
      // Open the selected tool after room membership and the audio join request.
      if (widget.initialMode == RoomMode.board ||
          widget.initialMode == RoomMode.lesson) {
        unawaited(_showBoard());
      } else if (widget.initialMode == RoomMode.quiz) {
        unawaited(_showQuiz());
      }
    } catch (error) {
      debugPrint('WorldVoice entry [$entryStage] '
          'project=${Firebase.app().options.projectId}: $error');
      if (!mounted) return;
      _leaving = true;
      _quotaTimer?.cancel();
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      final denied = error is FirebaseException &&
          error.code == 'permission-denied';
      final message = denied
          ? (isArabic
              ? 'رفضت Firebase صلاحية الدخول ($entryStage). تأكد من نشر قواعد الغرف الجديدة.'
              : 'Firebase denied room access ($entryStage). Check the published room rules.')
          : error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 10)),
      );
      if (membershipEstablished) {
        try {
          await _moderation.leave();
        } catch (cleanupError) {
          debugPrint('WorldVoice entry cleanup: $cleanupError');
        }
      }
      try {
        await _controller.leave();
      } finally {
        if (mounted) Navigator.of(context).pop();
      }
    }
  }

  void _handleTeacherAiVoice(
    List<RoomTeacherAiSpokenAnswer> messages,
  ) {
    if (!mounted || _leaving) return;
    if (messages.isEmpty) {
      _teacherAiVoicePrimed = true;
      return;
    }

    final latest = messages.first;
    if (!_showTeacherAiSeat) {
      _teacherAiVoicePrimed = true;
      _lastTeacherAiVoiceId = latest.id;
      return;
    }
    if (!_teacherAiVoicePrimed) {
      _teacherAiVoicePrimed = true;
      _lastTeacherAiVoiceId = latest.id;
      return;
    }
    if (latest.id == _lastTeacherAiVoiceId) return;
    _lastTeacherAiVoiceId = latest.id;
    final roomLanguage = (widget.roomLanguageCode ?? 'en').trim().toLowerCase();
    final answerLanguage = latest.languageCode.trim().toLowerCase();
    if (answerLanguage.isNotEmpty && answerLanguage != roomLanguage) return;
    _teacherAiSpeechSuppressedUntil =
        DateTime.now().add(const Duration(seconds: 8));
    unawaited(_speakRoomTeacher(latest.answer, roomLanguage));
  }

  void _handleCaptions(List<RoomCaption> captions) {
    if (!mounted) return;
    final latest = captions.isEmpty ? null : captions.first;
    setState(() {
      _latestCaption = latest;
      if (latest == null) {
        _latestTranslatedCaption = null;
        _lastTranslatedCaptionId = null;
      }
    });

    if (!_teacherAiAutoCaptionPrimed) {
      _teacherAiAutoCaptionPrimed = true;
      _lastTeacherAiAutoCaptionId = latest?.id;
    } else if (latest != null && latest.id != _lastTeacherAiAutoCaptionId) {
      _lastTeacherAiAutoCaptionId = latest.id;
      if (_shouldAutoAnswerCaption(latest)) {
        unawaited(_queueTeacherAiAutoReply(latest));
      }
    }

    if (latest != null &&
        _captionTranslationEnabled &&
        latest.id != _lastTranslatedCaptionId) {
      unawaited(_translateLatestCaption(latest));
    }

    if (latest != null &&
        _pronunciationTipsEnabled &&
        latest.userId == _moderation.currentUserId &&
        latest.id != _lastTeacherAiCaptionId) {
      _lastTeacherAiCaptionId = latest.id;
      unawaited(_requestPronunciationGuidance(latest));
    }
  }

  bool _shouldAutoAnswerCaption(RoomCaption caption) {
    if (!_showTeacherAiSeat ||
        _me?.role != RoomMemberRole.host ||
        !_teacherAi.isAskConfigured ||
        caption.text.trim().isEmpty) {
      return false;
    }
    final suppressedUntil = _teacherAiSpeechSuppressedUntil;
    if (suppressedUntil != null && DateTime.now().isBefore(suppressedUntil)) {
      return false;
    }
    final createdAt = caption.createdAt;
    if (createdAt != null &&
        DateTime.now().difference(createdAt).abs() >
            const Duration(seconds: 20)) {
      return false;
    }
    return true;
  }

  Future<void> _queueTeacherAiAutoReply(RoomCaption caption) async {
    if (_teacherAiAutoReplyBusy) {
      _queuedTeacherAiCaption = caption;
      return;
    }

    _teacherAiAutoReplyBusy = true;
    try {
      var current = caption;
      while (mounted && _showTeacherAiSeat && _me?.role == RoomMemberRole.host) {
        final prompt = current.text.trim();
        if (prompt.isNotEmpty) {
          try {
            await _teacherAi.ask(
              prompt: prompt,
              roomLanguageCode: widget.roomLanguageCode ?? 'en',
            );
          } catch (error) {
            debugPrint('WorldVoice Teacher AI auto reply failed: $error');
          }
        }

        final next = _queuedTeacherAiCaption;
        _queuedTeacherAiCaption = null;
        if (next == null || next.id == current.id) break;
        final suppressedUntil = _teacherAiSpeechSuppressedUntil;
        if (suppressedUntil != null &&
            DateTime.now().isBefore(suppressedUntil)) {
          break;
        }
        current = next;
      }
    } finally {
      _teacherAiAutoReplyBusy = false;
    }
  }

  Future<void> _requestPronunciationGuidance(RoomCaption caption) async {
    try {
      final received = await _teacherAi.submitCaption(
        caption: caption,
        roomLanguageCode: widget.roomLanguageCode ?? 'en',
      );
      if (!received && mounted && _pronunciationTipsEnabled) {
        setState(() => _captionError =
            'Pronunciation guidance needs the deployed Teacher AI backend.');
      }
    } catch (error) {
      if (mounted && _pronunciationTipsEnabled) {
        setState(() => _captionError = error.toString());
      }
    }
  }

  Future<void> _translateLatestCaption(RoomCaption caption) async {
    _lastTranslatedCaptionId = caption.id;
    try {
      final translated = await _translationService.translate(
        text: caption.text,
        sourceCode: caption.languageCode,
        targetCode: _captionTargetLanguage,
      );
      if (!mounted || _latestCaption?.id != caption.id) return;
      setState(() => _latestTranslatedCaption = translated);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _latestTranslatedCaption = null;
        _captionError = error.toString();
      });
    }
  }

  Future<void> _syncCaptionPublishing() async {
    final me = _me;
    final canPublish = _controller.joined &&
        me != null &&
        me.isOnStage &&
        !_controller.muted &&
        !me.forcedMuted;

    await _captionController.configure(
      enabled:
          _captionsEnabled || _pronunciationTipsEnabled || _showTeacherAiSeat,
      canPublish: canPublish,
      languageCode: widget.roomLanguageCode ?? 'en',
      displayName: me?.displayName ?? 'WorldVoice user',
    );
  }

  Future<void> _setCaptionsEnabled(bool value) async {
    if (mounted) {
      setState(() {
        _captionsEnabled = value;
        if (!value) {
          _latestTranslatedCaption = null;
          _captionError = null;
        }
      });
    }
    await _syncCaptionPublishing();
  }

  Future<void> _showTeacherAiChat() async {
    if (!_showTeacherAiSeat) {
      if (!mounted) return;
      final isArabic =
          Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'فعّل مقعد Teacher AI أولًا حتى يشارك ويتكلم داخل الروم.'
                : 'Show the Teacher AI seat first so it can join and speak in the room.',
          ),
        ),
      );
      return;
    }
    if (!_teacherAi.isAskConfigured) {
      if (!mounted) return;
      final isArabic =
          Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'يجب ربط Backend الخاص بـ Teacher AI أولاً.'
                : 'Teacher AI backend must be connected first.',
          ),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RoomTeacherAiSheet(
        service: _teacherAi,
        roomLanguageCode: widget.roomLanguageCode ?? 'en',
      ),
    );
  }

  Future<void> _showCaptionSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          void refreshSheet() => setSheetState(() {});

          return RoomCaptionsSheet(
            enabled: _captionsEnabled,
            translationEnabled: _captionTranslationEnabled,
            pronunciationEnabled: _pronunciationTipsEnabled,
            pronunciationNotes: _teacherAi.watchNotes().map(
              (notes) => notes
                  .where((note) => note.userId == _moderation.currentUserId)
                  .toList(growable: false),
            ),
            targetLanguage: _captionTargetLanguage,
            canPublish: _me?.isOnStage == true,
            listening: _captionListening,
            error: _captionError,
            onEnabledChanged: (value) {
              unawaited(_setCaptionsEnabled(value));
              refreshSheet();
            },
            onTranslationChanged: (value) {
              setState(() {
                _captionTranslationEnabled = value;
                _latestTranslatedCaption = null;
                _lastTranslatedCaptionId = null;
              });
              final latest = _latestCaption;
              if (value && latest != null) {
                unawaited(_translateLatestCaption(latest));
              }
              refreshSheet();
            },
            onPronunciationChanged: (value) {
              setState(() {
                _pronunciationTipsEnabled = value;
                _lastTeacherAiCaptionId = null;
                _captionError = null;
              });
              unawaited(_syncCaptionPublishing());
              final latest = _latestCaption;
              if (value && latest != null &&
                  latest.userId == _moderation.currentUserId) {
                _lastTeacherAiCaptionId = latest.id;
                unawaited(_requestPronunciationGuidance(latest));
              }
              refreshSheet();
            },
            onTargetLanguageChanged: (value) {
              setState(() {
                _captionTargetLanguage = value;
                _latestTranslatedCaption = null;
                _lastTranslatedCaptionId = null;
              });
              final latest = _latestCaption;
              if (_captionTranslationEnabled && latest != null) {
                unawaited(_translateLatestCaption(latest));
              }
              refreshSheet();
            },
          );
        },
      ),
    );
  }

  Future<void> _checkLiveQuota() async {
    if (_leaving || _quotaEnding) return;
    final status = await _quota.currentSessionStatus();
    if (status.allowed || status.isUnlimited || !mounted) return;

    _quotaEnding = true;

    // Stop RTC immediately at the quota boundary and persist the consumed time.
    await _controller.leave();
    await _quota.endSession();

    if (!mounted) return;

    // Hosts use their separate 4h + room-level allowance and do not get
    // the listener rewarded-ad extension.
    if (_isHost) {
      await _finishQuotaExit();
      return;
    }

    var current = await _quota.check(
      asHost: false,
      roomLevel: _featureState.roomLevel,
    );

    while (mounted &&
        current.adsWatched < 3 &&
        current.adBonusSeconds < 3 * 60 * 60) {
      final watch = await _askForRewardedAd(current);
      if (watch != true || !mounted) {
        await _finishQuotaExit();
        return;
      }

      final earned = await _rewardedAds.show();
      if (!mounted) return;

      if (!earned) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'لم يكتمل الإعلان، لذلك لم يتم احتسابه.'
                  : 'The ad was not completed, so it was not counted.',
            ),
          ),
        );
        continue;
      }

      current = await _quota.recordRewardedAdWatched();
    }

    current = await _quota.check(
      asHost: false,
      roomLevel: _featureState.roomLevel,
    );

    if (!current.allowed) {
      await _finishQuotaExit();
      return;
    }

    final restarted = await _quota.startSession(
      asHost: false,
      roomLevel: _featureState.roomLevel,
    );
    if (!restarted.allowed || !mounted) {
      await _finishQuotaExit();
      return;
    }

    _lastSyncedAgoraUid = null;
    final desiredRole = _me?.isOnStage == true
        ? AgoraRoomRole.speaker
        : AgoraRoomRole.listener;
    await _controller.connect(
      channelId: widget.channelId,
      role: desiredRole,
    );

    _quotaEnding = false;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'تمت إضافة 3 ساعات إضافية اليوم.'
                : '3 extra room hours were added for today.',
          ),
        ),
      );
    }
  }

  Future<bool?> _askForRewardedAd(RoomQuotaStatus status) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final next = (status.adsWatched + 1).clamp(1, 3);

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isArabic ? 'وقت إضافي للغرف' : 'Get more room time',
        ),
        content: Text(
          isArabic
              ? 'شاهد الإعلان $next من 3 كاملًا. بعد إكمال 3 إعلانات تحصل على 3 ساعات إضافية اليوم.'
              : 'Watch rewarded ad $next of 3 completely. Completing all 3 adds 3 extra hours today.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(isArabic ? 'خروج من الغرفة' : 'Leave room'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.ondemand_video_rounded),
            label: Text(isArabic ? 'مشاهدة الإعلان' : 'Watch ad'),
          ),
        ],
      ),
    );
  }

  Future<void> _finishQuotaExit() async {
    if (!mounted) return;
    _leaving = true;
    await _history.recordLeave(widget.channelId);
    await _moderation.leave();

    if (!mounted) return;
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
  }

  Future<void> _showQuotaStatus() async {
    final status = await _quota.currentSessionStatus();
    if (!mounted) return;
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    String formatSeconds(int value) {
      final hours = value ~/ 3600;
      final minutes = (value % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isArabic ? 'وقت الغرف اليومي' : 'Daily room time'),
        content: status.isUnlimited
            ? Text(
                isArabic
                    ? 'VIP: وقت الغرف غير محدود.'
                    : 'VIP: room time is unlimited.',
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${isArabic ? 'المتبقي' : 'Remaining'}: '
                    '${formatSeconds(status.remainingSeconds)}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${isArabic ? 'المستخدم' : 'Used'}: '
                    '${formatSeconds(status.usedSeconds)}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${isArabic ? 'الإعلانات المكتملة' : 'Rewarded ads completed'}: '
                    '${status.adsWatched}/3',
                  ),
                  if (status.adsWatched < 3) ...[
                    const SizedBox(height: 12),
                    Text(
                      _rewardedAds.usesTestAd
                          ? (isArabic
                              ? 'النسخة الحالية تستخدم إعلان Google الاختباري. قبل النشر العام نستبدله بإعلان WorldVoice الحقيقي.'
                              : 'This test build uses Google test rewarded ads. Replace them with WorldVoice production ad IDs before public release.')
                          : (isArabic
                              ? 'يتم احتساب الإعلان فقط بعد إكمال المشاهدة.'
                              : 'An ad only counts after the rewarded view is completed.'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(isArabic ? 'إغلاق' : 'Close'),
          ),
        ],
      ),
    );
  }

  void _showGiftOverlay(RoomGiftEvent gift, {
    bool preview = false,
    RoomGiftCatalogItem? previewGift,
  }) {
    if (!mounted) return;

    _giftOverlayTimer?.cancel();
    _giftOverlay?.remove();

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => RoomGiftOverlay(
        event: gift, preview: preview, previewGift: previewGift),
    );
    _giftOverlay = entry;
    overlay.insert(entry);

    final normalizedGiftId = gift.giftId.trim().toLowerCase();
    final isPremiumDragon = const <String>{
      'dragon',
      'caraxes',
      'vhagar',
    }.contains(normalizedGiftId);

    _giftOverlayTimer = Timer(
      Duration(seconds: isPremiumDragon ? 5 : 3),
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

  Future<void> _synchronizeParticipantAudio() async {
    if (_roleUpdateInProgress || !_controller.joined || _me == null ||
        _leaving) {
      return;
    }
    _roleUpdateInProgress = true;
    try {
      final participant = _me!;
      final role = participant.isOnStage
          ? AgoraRoomRole.speaker
          : AgoraRoomRole.listener;
      if (_controller.role != role) {
        await _controller.switchRole(role);
      }
      // Only the host can set forcedMuted. Never unmute on the member's
      // behalf when moderation lifts it: the member chooses when to speak.
      if (_me?.isOnStage == true && _me?.forcedMuted == true &&
          _controller.role == AgoraRoomRole.speaker &&
          !_controller.muted) {
        await _controller.setMuted(true);
      }
      await _syncCaptionPublishing();
    } catch (error) {
      debugPrint('WorldVoice audio-role synchronization: $error');
      if (mounted && !_leaving) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      _roleUpdateInProgress = false;
    }
  }

  Future<void> _retryAudioConnection() async {
    if (_audioRetrying || _leaving) return;
    setState(() {
      _audioRetrying = true;
      _audioFailure = null;
    });
    try {
      await _controller.ensureConnected(
        channelId: widget.channelId,
        role: (_me?.isOnStage ?? (widget.initialRole == AgoraRoomRole.speaker))
            ? AgoraRoomRole.speaker : AgoraRoomRole.listener,
      );
      await _synchronizeParticipantAudio();
      if (mounted) setState(() => _audioFailure = null);
    } catch (error) {
      if (mounted) setState(() => _audioFailure = error.toString());
    } finally {
      if (mounted) setState(() => _audioRetrying = false);
    }
  }

  Future<void> _toggleMicSafely() async {
    if (_micBusy || _leaving || !_controller.joined ||
        _me?.isOnStage != true) {
      return;
    }
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    if (_me?.forcedMuted == true || _roleUpdateInProgress) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ar
            ? 'الميكروفون مقفل من المضيف أو جاري تحديث المقعد.'
            : 'The host muted you, or your speaking seat is still updating.'),
      ));
      return;
    }
    setState(() => _micBusy = true);
    try {
      if (_controller.role != AgoraRoomRole.speaker) {
        await _controller.switchRole(AgoraRoomRole.speaker);
      }
      if (_controller.role != AgoraRoomRole.speaker) {
        throw StateError(_controller.error ??
            'Microphone is not available. Check audio permissions.');
      }
      await _controller.setMuted(!_controller.muted);
      await _syncCaptionPublishing();
    } catch (error) {
      if (mounted && !_leaving) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString()),
        ));
      }
    } finally {
      if (mounted) setState(() => _micBusy = false);
    }
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
    unawaited(_synchronizeParticipantAudio());
  }

  void _handleStageInvite(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!mounted || !snapshot.exists || _leaving) return;
    final data = snapshot.data() ?? const <String, dynamic>{};
    if (data['status']?.toString() != 'pending') return;
    final createdAt = data['createdAt'];
    if (createdAt is! Timestamp) return;
    final signature =
        '${data['invitedBy']}|${data['role']}|${data['seatIndex']}|${createdAt.millisecondsSinceEpoch}';
    if (_lastStageInviteSignature == signature) return;
    _lastStageInviteSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_leaving) {
        unawaited(_showStageInvitePrompt(data));
      }
    });
  }

  Future<void> _showStageInvitePrompt(Map<String, dynamic> data) async {
    final ar =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final seatIndex = (data['seatIndex'] as num?)?.toInt();
    final role = RoomParticipant.roleFromString(data['role']?.toString());
    final roleLabel = switch (role) {
      RoomMemberRole.coHost => ar ? 'مساعد المضيف' : 'Co-host',
      RoomMemberRole.vipSeat => ar ? 'مقعد VIP' : 'VIP seat',
      _ => ar ? 'متحدث' : 'Speaker',
    };
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(ar ? 'دعوة للصعود' : 'Stage invitation'),
        content: Text(
          ar
              ? 'تمت دعوتك للصعود كـ $roleLabel${seatIndex == null ? '' : ' على المقعد $seatIndex'}. هل تقبل؟'
              : 'You were invited to join as $roleLabel${seatIndex == null ? '' : ' on seat $seatIndex'}. Accept?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(ar ? 'رفض' : 'Decline'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.keyboard_double_arrow_up_rounded),
            label: Text(ar ? 'قبول والصعود' : 'Accept & join'),
          ),
        ],
      ),
    );
    if (accepted == null) return;
    try {
      await _moderation.respondToStageInvite(accept: accepted);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
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

    unawaited(_synchronizeParticipantAudio());
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

  // A compact emerald hand button stays separate from chat actions.
  Widget _buildHandControl(bool isArabic, bool isPublishing) {
    // Request management is backed by Firestore. Keep the button visible
    // while the user retries a failed Agora audio connection.
    if (_me == null) return const SizedBox.shrink();
    if (_canModerate) {
      return Badge(
        isLabelVisible: _raisedHands.isNotEmpty,
        label: Text('${_raisedHands.length}'),
        backgroundColor: const Color(0xFFFFD57F),
        textColor: const Color(0xFF164434),
        child: Material(
          elevation: 4,
          color: const Color(0xFF087951),
          shape: const CircleBorder(
            side: BorderSide(color: Color(0xFF75E0AB), width: 1.2)),
          child: IconButton(
            constraints: const BoxConstraints.tightFor(width: 38, height: 38),
            padding: EdgeInsets.zero,
            tooltip: isArabic ? 'طلبات رفع اليد' : 'Raise hand requests',
            icon: const Icon(Icons.pan_tool_alt_rounded,
              size: 19, color: Colors.white),
            onPressed: _showRaisedHandsSheet,
          ),
        ),
      );
    }
    if (isPublishing) return const SizedBox.shrink();
    return Stack(clipBehavior: Clip.none, children: [
      Material(
        elevation: 4,
        color: _handRaised
            ? const Color(0xFF18A66D) : const Color(0xFF087951),
        shape: const CircleBorder(
          side: BorderSide(color: Color(0xFF75E0AB), width: 1.2)),
        child: IconButton(
          constraints: const BoxConstraints.tightFor(width: 38, height: 38),
          padding: EdgeInsets.zero,
          tooltip: _handRaised
              ? (isArabic ? 'إلغاء رفع اليد' : 'Cancel hand request')
              : (isArabic ? 'رفع اليد' : 'Raise hand'),
          icon: const Icon(Icons.pan_tool_alt_rounded,
              color: Colors.white, size: 19),
          onPressed: () async {
            try {
              if (_handRaised) {
                await _moderation.setHandRaised(false);
              } else {
                await _requestSeat();
              }
            } catch (error) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(isArabic
                    ? 'تعذر إرسال طلب رفع اليد: $error'
                    : 'Could not update hand request: $error'),
              ));
            }
          },
        ),
      ),
      if (_handRaised)
        const Positioned(
          top: -2, right: -2,
          child: CircleAvatar(radius: 6,
            backgroundColor: Color(0xFFEAC16B),
            child: Icon(Icons.check_rounded,
              size: 9, color: Color(0xFF0D4A38))),
        ),
    ]);
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
        frameId: participant.frameId,
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

    final rateable = _participants
        .where(
          (participant) =>
              participant.isOnStage &&
              participant.userId != _moderation.currentUserId,
        )
        .toList(growable: false);

    if (rateable.isNotEmpty && mounted) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => RoomRatingSheet(
          roomId: widget.channelId,
          participants: rateable,
        ),
      );
    }

    if (!mounted || _leaving) return;
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
    RoomParticipant? participant;
    for (final value in _participants) {
      if (value.userId == userId) {
        participant = value;
        break;
      }
    }
    final target = participant;
    final canInvite =
        target != null && target.role == RoomMemberRole.listener && _canModerate;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          userId: userId,
          languageCode:
              Localizations.localeOf(context).languageCode.toLowerCase(),
          onInviteToStage: !canInvite
              ? null
              : () async {
                  final seatIndex = _firstFreeSeat;
                  if (seatIndex == null || seatIndex == 1) {
                    throw StateError('All speaker seats are occupied.');
                  }
                  await _moderation.sendStageInvite(
                    userId: userId,
                    role: RoomMemberRole.speaker,
                    seatIndex: seatIndex,
                  );
                },
          inviteToStageLabel:
              Localizations.localeOf(context).languageCode.toLowerCase() == 'ar'
                  ? 'دعوة للصعود للروم'
                  : 'Invite to room stage',
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
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: StreamBuilder<List<RoomParticipant>>(
          // Live request list: no need to close/reopen to see another member
          // raise or withdraw their hand.
          stream: _moderation.watchParticipants(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 170,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final hands = snapshot.data!
                .where((member) =>
                    member.role == RoomMemberRole.listener &&
                    member.handRaised)
                .toList(growable: false);
            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                ListTile(
                  leading: const Icon(Icons.pan_tool_alt_rounded),
                  title: Text(
                    isArabic ? 'طلبات رفع اليد' : 'Raise hand requests',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(isArabic
                      ? '${hands.length} طلب'
                      : '${hands.length} request(s)'),
                ),
                if (hands.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(isArabic
                          ? 'لا توجد طلبات حاليًا'
                          : 'No pending requests'),
                    ),
                  ),
                for (final participant in hands)
                  ListTile(
                    leading: _ParticipantAvatar(participant: participant),
                    title: Text(participant.displayName),
                    subtitle: participant.requestedSeatIndex == null
                        ? Text(isArabic ? 'يريد الصعود' : 'Wants to speak')
                        : Text(isArabic
                            ? 'طلب المقعد ${participant.requestedSeatIndex}'
                            : 'Requested seat ${participant.requestedSeatIndex}'),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        IconButton(
                          tooltip: isArabic ? 'رفض' : 'Reject',
                          onPressed: () async {
                            try {
                              await _moderation.rejectHand(participant.userId);
                            } catch (_) {
                              if (!sheetContext.mounted) return;
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                SnackBar(content: Text(isArabic
                                    ? 'تعذر رفض الطلب'
                                    : 'Could not reject the request')),
                              );
                            }
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                        IconButton.filled(
                          tooltip: isArabic ? 'موافقة' : 'Accept',
                          onPressed: () async {
                            try {
                              await _acceptHand(participant);
                              if (sheetContext.mounted) Navigator.pop(sheetContext);
                            } catch (_) {
                              if (!sheetContext.mounted) return;
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                SnackBar(content: Text(isArabic
                                    ? 'تعذر قبول الطلب. تحقق من المقاعد.'
                                    : 'Could not accept request. Check seats.')),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_rounded),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showCoinStore() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const RoomCoinStoreSheet(),
    );
  }

  Future<void> _showBackgroundStore() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RoomBackgroundShopSheet(
        roomFeatures: _features,
        isHost: _isHost,
        // The shared board already supports text and a multi-color palette.
        onOpenWriting: _isHost || _featureState.boardWriteEnabled
            ? _expandBoard
            : null,
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

  bool _boardVisible = false;
  Future<void> _showBoard() async {
    setState(() => _boardVisible = true);
  }

  Future<void> _expandBoard() async {
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
    final privateCode = widget.privateAccessCode?.trim() ?? '';
    final accessLine = widget.initialIsPrivate && privateCode.isNotEmpty
        ? '\nPrivate code: $privateCode'
        : '';

    await SharePlus.instance.share(
      ShareParams(
        text: 'WorldVoice • ${widget.roomName}'
            '${language.isEmpty ? '' : ' • $language'}'
            '$accessLine',
      ),
    );
  }

  Future<void> _showRoomExtras({int initialTab = 0}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RoomExtrasSheet(
        initialTab: initialTab,
        roomId: widget.channelId,
      ),
    );
  }

  // Gifts are a self-contained tool, never a tab inside themes or tasks.
  Future<void> _showGifts() async {
    final myId = FirebaseAuth.instance.currentUser?.uid;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: UnifiedGiftPanel(
            contextType: widget.initialMode == RoomMode.live ? 'live' : 'room',
            contextId: widget.channelId,
            recipients: {
              for (final member in _participants.where(
                  (member) => member.userId != myId &&
                      (member.isOnStage ||
                          RoomFeatureService.friendPreviewEnabled)))
                member.userId: member.displayName,
              if (_showTeacherAiSeat && widget.initialMode != RoomMode.live)
                'teacher_ai': 'Teacher AI',
            },
            onOpenCoinStore: _showCoinStore,
            onPreview: (gift, recipientId) {
              // Local effect test over the real seats: never write a gift
              // document, debit coins or display a sent-gift receipt.
              Navigator.pop(sheetContext);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _showGiftOverlay(RoomGiftEvent(
                  id: 'preview',
                  senderId: myId ?? '',
                  senderName: _me?.displayName ??
                      FirebaseAuth.instance.currentUser?.displayName ??
                      'WorldVoice',
                  recipientId: recipientId ?? '',
                  recipientName: widget.initialMode != RoomMode.live &&
                          recipientId == 'teacher_ai'
                      ? 'Teacher AI'
                      : _participants.where(
                          (p) => p.userId == recipientId).isNotEmpty
                        ? _participants.firstWhere(
                            (p) => p.userId == recipientId).displayName
                        : (recipientId == null
                            ? (Localizations.localeOf(context).languageCode == 'ar'
                                ? 'اختر المستلم' : 'Select recipient')
                            : 'Member'),
                  giftId: gift.id,
                  points: gift.priceCoins,
                ), preview: true, previewGift: gift);
              });
            },
          ),
        ),
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

  Future<void> _confirmCloseRoom() async {
    if (!_isHost || _leaving || !mounted) return;

    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isArabic ? 'إغلاق الروم؟' : 'Close room?'),
        content: Text(
          isArabic
              ? 'سيتم إنهاء الروم وإخراج جميع الموجودين منه.'
              : 'This will end the room and disconnect everyone in it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.stop_circle_rounded),
            label: Text(isArabic ? 'إغلاق الروم' : 'Close room'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _moderation.closeRoom();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _showRoomMenu() async {
    final ar = (widget.localeController?.locale?.languageCode ?? Localizations.localeOf(context).languageCode) == 'ar';
    await showModalBottomSheet<void>(
      context: context, showDragHandle: true, useSafeArea: true,
      builder: (ctx) => Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.share_outlined), title: Text(ar ? 'مشاركة الغرفة' : 'Share room'),
            onTap: () { Navigator.pop(ctx); _shareRoom(); }),
          if (widget.localeController != null)
            ListTile(leading: const Icon(Icons.picture_in_picture_alt_outlined), title: Text(ar ? 'تصغير نافذة الغرفة' : 'Minimize room'),
              onTap: () { Navigator.pop(ctx); _minimizeRoom(); }),
          ListTile(leading: const Icon(Icons.logout_rounded), title: Text(ar ? 'مغادرة' : 'Leave'),
            onTap: () { Navigator.pop(ctx); _leave(); }),
          if (_isHost) ListTile(leading: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
            title: Text(ar ? 'إغلاق الغرفة للجميع' : 'Close room for everyone', style: const TextStyle(color: Colors.redAccent)),
            onTap: () { Navigator.pop(ctx); _confirmCloseRoom(); }),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(ar ? 'إلغاء' : 'Cancel'))),
        ])),
    );
  }

  // Tapping the room title opens only the five working room controls.
  // Host/moderation controls remain role-gated.
  Future<void> _showTitleActions() async {
    final ar = (widget.localeController?.locale?.languageCode ??
        Localizations.localeOf(context).languageCode) == 'ar';
    final items = <(IconData, String, VoidCallback)>[
      if (_canModerate)
        (Icons.admin_panel_settings_rounded,
          ar ? 'المدير' : 'Moderator', _showRoomControls),
      (Icons.chat_bubble_outline_rounded,
        ar ? 'الشات' : 'Chat', _showRoomChat),
      (Icons.music_note_rounded,
        ar ? 'الموسيقى' : 'Music', _showMusic),
      (Icons.draw_rounded,
        ar ? 'السبورة' : 'Whiteboard', _showBoard),
      (Icons.quiz_outlined,
        ar ? 'الكويز' : 'Quiz', _showQuiz),
    ];
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ar ? 'التحكم بالغرفة' : 'Room controls',
                style: Theme.of(sheet).textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final item in items)
                ListTile(
                  leading: Icon(item.$1),
                  title: Text(item.$2),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(sheet);
                    item.$3();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // The four squares in the bottom toolbar open these four tools only.
  Future<void> _showToolsGrid() async {
    final ar = (widget.localeController?.locale?.languageCode ??
        Localizations.localeOf(context).languageCode) == 'ar';
    final items = <(IconData, String, VoidCallback)>[
      (Icons.castle_outlined, ar ? 'مهام الغرفة' : 'Room tasks',
        () => _showRoomExtras(initialTab: 0)),
      (Icons.card_giftcard_rounded, ar ? 'الهدايا' : 'Gifts', _showGifts),
      (Icons.timer_outlined, ar ? 'الوقت المتبقي' : 'Remaining time',
        _showQuotaStatus),
      (Icons.groups_outlined,
        ar ? 'الأعضاء: ${_participants.length}' : 'Members: ${_participants.length}',
        _showMembers),
    ];
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheet) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ar ? 'مركز الغرفة' : 'Room center',
              style: Theme.of(sheet).textTheme.titleLarge),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 104,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (ctx, index) {
                final item = items[index];
                return Material(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.pop(sheet);
                      item.$3();
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.$1, size: 29),
                        const SizedBox(height: 8),
                        Text(item.$2, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Host-only live moderator management; use the existing admin service
  // instead of creating a second roles or permissions implementation.
  Future<void> _showModeratorManagement() async {
    if (!_isHost) return;
    final ar = (widget.localeController?.locale?.languageCode ??
        Localizations.localeOf(context).languageCode) == 'ar';
    final admin = RoomAdminService(roomId: widget.channelId);
    final membersStream = _moderation.watchParticipants();
    String? savingUser;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * .7,
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_rounded,
                    color: Color(0xFF11835D)),
                title: Text(ar ? 'إدارة المشرفين' : 'Manage moderators',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(ar
                    ? 'عيّن مشرفاً من أعضاء الغرفة أو أزل صلاحياته'
                    : 'Add or remove moderators among current room members'),
              ),
              const Divider(height: 1),
              Expanded(child: StreamBuilder<List<RoomParticipant>>(
                stream: membersStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text(ar
                        ? 'تعذر تحميل أعضاء الغرفة'
                        : 'Could not load room members'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final eligible = snapshot.data!
                      .where((person) => person.role != RoomMemberRole.host)
                      .toList()
                    ..sort((a, b) {
                      if (a.isModerator != b.isModerator) {
                        return a.isModerator ? -1 : 1;
                      }
                      return a.displayName.toLowerCase()
                          .compareTo(b.displayName.toLowerCase());
                    });
                  if (eligible.isEmpty) {
                    return Center(child: Text(ar
                        ? 'لا يوجد أعضاء آخرون في الغرفة بعد'
                        : 'No other members are in this room yet'));
                  }
                  return ListView.builder(
                    itemCount: eligible.length,
                    itemBuilder: (context, index) {
                      final person = eligible[index];
                      return ListTile(
                        leading: _ParticipantAvatar(participant: person),
                        title: Text(person.displayName,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(person.isModerator
                            ? (ar ? 'مشرف حالي' : 'Current moderator')
                            : (ar ? 'عضو' : 'Member')),
                        trailing: FilledButton.tonal(
                          onPressed: savingUser != null ? null : () async {
                            setSheetState(() => savingUser = person.userId);
                            try {
                              await admin.setModerator(
                                participant: person,
                                value: !person.isModerator,
                              );
                            } catch (error) {
                              if (sheetContext.mounted) {
                                ScaffoldMessenger.of(sheetContext)
                                    .showSnackBar(SnackBar(
                                      content: Text(error.toString())));
                              }
                            } finally {
                              if (sheetContext.mounted) {
                                setSheetState(() => savingUser = null);
                              }
                            }
                          },
                          child: savingUser == person.userId
                              ? const SizedBox.square(dimension: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : Text(person.isModerator
                                  ? (ar ? 'إزالة' : 'Remove')
                                  : (ar ? 'تعيين' : 'Add')),
                        ),
                      );
                    },
                  );
                },
              )),
            ]),
          ),
        ),
      ),
    );
  }

  // Moderator panel, never used as the gift/theme/task menu.
  Future<void> _showRoomControls() async {
    if (!_canModerate) return;
    final ar = (widget.localeController?.locale?.languageCode ??
        Localizations.localeOf(context).languageCode) == 'ar';
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              title: Text(ar ? 'إدارة الغرفة' : 'Room moderation',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            if (_isHost) SwitchListTile(
              title: const Text('Teacher AI'),
              subtitle: Text(ar ? 'إظهار المقعد التاسع'
                  : 'Show the ninth AI seat'),
              value: _showTeacherAiSeat,
              onChanged: (value) async {
                try {
                  await _moderation.setTeacherAiSeatVisible(value);
                  if (sheet.mounted) Navigator.pop(sheet);
                } catch (error) {
                  if (sheet.mounted) {
                    ScaffoldMessenger.of(sheet).showSnackBar(
                      SnackBar(content: Text(error.toString())));
                  }
                }
              },
            ),
            if (_isHost) SwitchListTile(
              title: Text(ar ? 'السماح بالكتابة والرسم'
                  : 'Allow writing and drawing'),
              value: _featureState.boardWriteEnabled,
              onChanged: (value) async {
                try {
                  await _features.setBoardWriteEnabled(value);
                  if (sheet.mounted) Navigator.pop(sheet);
                } catch (error) {
                  if (sheet.mounted) {
                    ScaffoldMessenger.of(sheet).showSnackBar(
                      SnackBar(content: Text(error.toString())));
                  }
                }
              },
            ),
            if (_isHost) ListTile(
              leading: const Icon(Icons.admin_panel_settings_rounded,
                  color: Color(0xFF11835D)),
              title: Text(ar ? 'إضافة أو إزالة المشرفين' : 'Manage moderators'),
              onTap: () {
                Navigator.pop(sheet);
                _showModeratorManagement();
              },
            ),
            ListTile(
              leading: const Icon(Icons.pan_tool_alt_rounded),
              title: Text(ar ? 'طلبات رفع اليد' : 'Raise hand requests'),
              trailing: Badge(label: Text('${_raisedHands.length}'),
                child: const Icon(Icons.chevron_right_rounded)),
              onTap: () {
                Navigator.pop(sheet);
                _showRaisedHandsSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_rounded),
              title: Text(ar ? 'سجل المودريتور' : 'Moderator log'),
              onTap: () {
                Navigator.pop(sheet);
                _showModLog();
              },
            ),
            if (_isHost) ListTile(
              leading: const Icon(Icons.stop_circle_outlined,
                color: Colors.redAccent),
              title: Text(ar ? 'إغلاق الغرفة للجميع'
                  : 'Close room for everyone'),
              onTap: () {
                Navigator.pop(sheet);
                _confirmCloseRoom();
              },
            ),
          ]),
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

    await _moderation.sendStageInvite(
      userId: participant.userId,
      role: selectedRole,
      seatIndex: seatIndex,
    );
    if (!mounted) return;
    final ar =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ar
              ? 'تم إرسال الدعوة. لن يصعد المستخدم إلا بعد الموافقة.'
              : 'Invite sent. The member will join only after accepting.',
        ),
      ),
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
    _freeGiftPreviewSub?.cancel();
    _freeChatGiftSub?.cancel();
    _captionSub?.cancel();
    _teacherAiSub?.cancel();
    _teacherAiVoiceSub?.cancel();
    _stageInviteSub?.cancel();
    _giftOverlayTimer?.cancel();
    _speakingTimer?.cancel();
    _quotaTimer?.cancel();
    _giftOverlay?.remove();
    _giftOverlay = null;
    _controller.removeListener(_refresh);
    unawaited(_captionController.dispose());
    unawaited(_translationService.dispose());
    unawaited(_stopRoomTeacherVoice());
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
      case 'skyBlue':
        return const [
          Color(0xFF145C76),
          Color(0xFF123B56),
          Color(0xFF0B2535),
        ];
      case 'forestGold':
        return const [
          Color(0xFF265338),
          Color(0xFF284A39),
          Color(0xFF17322A),
        ];
      case 'midnight':
        return const [
          Color(0xFF17223A),
          Color(0xFF111827),
          Color(0xFF090D16),
        ];
      default:
        return const [
          Color(0xFF0D4A38),
          Color(0xFF123A32),
          Color(0xFF111D1A),
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
    if (_minimized) return _buildMinimizedRoom(context);
    final isArabic = (widget.localeController?.locale?.languageCode ??
        Localizations.localeOf(context).languageCode) == 'ar';
    final isPublishing = _me?.isOnStage ?? (widget.initialRole == AgoraRoomRole.speaker);
    String label(String ar, String en) => isArabic ? ar : en;
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        // Only the chat composer moves over the keyboard; seats stay fixed.
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFF0D4A38),
        appBar: AppBar(
          toolbarHeight: _boardVisible ? 52 : 68, elevation: 0,
          backgroundColor: const Color(0xFF0D4A38), foregroundColor: Colors.white,
          leading: IconButton(tooltip: label('قائمة الغرفة', 'Room menu'),
            onPressed: _showRoomMenu, icon: const Icon(Icons.more_horiz_rounded)),
          titleSpacing: 0,
          title: InkWell(
            onTap: _showTitleActions,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.roomName, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                InkWell(onTap: () => _showRoomExtras(initialTab: 0), child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFFFCE79),
                    borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.castle_rounded, size: 13, color: Color(0xFF603D15)),
                    Text(' Lv.${_featureState.roomLevel}', style: const TextStyle(
                      color: Color(0xFF603D15), fontSize: 10, fontWeight: FontWeight.w800)),
                  ]),
                )),
                Text((widget.roomLanguageCode ?? 'en').toUpperCase(),
                  style: const TextStyle(color: Colors.white70, fontSize: 10)),
                Text(_controller.joined ? label('• متصل', '• Live') : label('• الصوت غير متصل', '• Audio offline'),
                  style: TextStyle(color: _controller.joined ? const Color(0xFF88EDBC) : Colors.white60, fontSize: 10)),
              ]),
            ]),
          ),
          actions: [
            if (_boardVisible && _controller.error != null) IconButton(
              tooltip: label('خطأ اتصال الصوت', 'Audio connection error'),
              icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFD68A)),
              onPressed: () => showDialog<void>(context: context, builder: (ctx) => AlertDialog(
                content: SelectableText(_controller.error!),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(label('إغلاق', 'Close')))]))),
            IconButton(tooltip: label('الأعضاء', 'Members'), onPressed: _showMembers,
              icon: Badge(label: Text('${_participants.length}'), child: const Icon(Icons.people_outline_rounded))),
            IconButton(tooltip: label('تصغير', 'Minimize'), onPressed: widget.localeController == null ? null : _minimizeRoom,
              icon: const Icon(Icons.picture_in_picture_alt_outlined, size: 21)),
          ],
        ),
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: _roomThemeColors(_featureState.themeId)),
            image: _featureState.backgroundUrl?.trim().isNotEmpty == true
              ? DecorationImage(image: NetworkImage(_featureState.backgroundUrl!.trim()),
                  fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: .25), BlendMode.darken))
              : null,
          ),
          child: SafeArea(top: false, child: Column(children: [
            if (_controller.connecting) const LinearProgressIndicator(minHeight: 2),
            if ((_controller.error != null || _audioFailure != null) && !_boardVisible) Container(
              width: double.infinity, margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF4D344E), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFFFFD3A4), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label('الصوت غير متصل. افتح التفاصيل أو أعد المحاولة.',
                        'Audio offline. Check details or retry.'),
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                    if (MediaQuery.viewInsetsOf(context).bottom == 0)
                      Text(_audioFailure ?? _controller.error ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFFFE3BE),
                            fontSize: 10)),
                  ],
                )),
                IconButton(tooltip: label('تفاصيل الاتصال', 'Connection details'),
                  onPressed: () => showDialog<void>(context: context, builder: (ctx) => AlertDialog(
                    title: Text(label('اتصال الصوت', 'Audio connection')),
                    content: SingleChildScrollView(child: SelectableText(_audioFailure ?? _controller.error ?? 'Unknown Agora error')),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(label('إغلاق', 'Close')))],
                  )), icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 18)),
                IconButton(
                  tooltip: label('إعادة اتصال الصوت', 'Retry audio'),
                  onPressed: _audioRetrying ? null : _retryAudioConnection,
                  icon: _audioRetrying
                    ? const SizedBox.square(dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 20),
                ),
              ]),
            ),
            Expanded(child: LayoutBuilder(builder: (context, constraints) {
              // Reserve actual two-row seat height instead of letting a short
              // viewport scroll or clip the stage. Chat is the only vertical
              // message scroller; tiny/keyboard viewports use compact mode.
              final stageHeight =
                  2 * (82 + MediaQuery.textScalerOf(context).scale(30)) + 24;
              final contentHeight = _boardVisible
                  ? (constraints.maxHeight * .55).clamp(110.0, 320.0) + 106
                  : stageHeight + (_showTeacherAiSeat ? 88 : 0);
              final neededHeight = contentHeight +
                  (_controller.joined ? 42 : 0) +
                  (_canModerate && _raisedHands.isNotEmpty ? 84 : 0) +
                  130;
              final compact = constraints.maxHeight < neededHeight;
              return Column(children: [
                if (_boardVisible) SizedBox(
                  height: (constraints.maxHeight * .55).clamp(110.0, 320.0),
                  child: RoomBoardScreen(roomId: widget.channelId,
                    canWrite: _isHost || _featureState.boardWriteEnabled,
                    isHost: _isHost, agoraController: _controller, embedded: true,
                    onExpand: _expandBoard, onClose: () => setState(() => _boardVisible = false))),
                if (_boardVisible && !compact) SizedBox(height: 106,
                  child: RoomStageStrip(seats: _buildSeats(), onSeatTap: _handleSeatTap)),
                // Stage is a separate fixed viewport. Teacher AI and hand
                // requests stay pinned; new chat messages never scroll them.
                if (!_boardVisible && !compact) SizedBox(
                  height: stageHeight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: RoomStageGrid(seats: _buildSeats(),
                      onSeatTap: _handleSeatTap,
                      onSeatLongPress: _handleSeatLongPress),
                  ),
                ),
                if (!_boardVisible && !compact && _showTeacherAiSeat)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: _TeacherAiCompactSeat(
                      note: _latestTeacherAiNote,
                      configured: _teacherAi.isConfigured || _teacherAi.isAskConfigured,
                      onTap: _showTeacherAiChat,
                    ),
                  ),
                if (!compact && _canModerate && _raisedHands.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _RaisedHandNotice(
                      participant: _raisedHands.first, total: _raisedHands.length,
                      isArabic: isArabic,
                      onTap: _showRaisedHandsSheet,
                      onAccept: () => _acceptHand(_raisedHands.first),
                      onReject: () => _moderation.rejectHand(_raisedHands.first.userId),
                    ),
                  ),
                if (_captionsEnabled && _latestCaption != null && !compact)
                  RoomCaptionOverlay(caption: _latestCaption!, translationEnabled: _captionTranslationEnabled,
                    translatedText: _latestTranslatedCaption),
                if (_featureState.quizQuestion != null && !compact)
                  Align(alignment: AlignmentDirectional.centerEnd, child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ActionChip(avatar: const Icon(Icons.quiz_outlined, size: 16),
                      label: Text(label('مسابقة الغرفة', 'Room quiz')), onPressed: _showQuiz))),
                Expanded(child: Stack(children: [
                  Positioned.fill(child: RoomConversationPanel(
                  messages: _chatMessages ?? const Stream<List<RoomChatMessage>>.empty(),
                  enabled: _chatMessages != null, onSend: _roomChat.send, isArabic: isArabic,
                  onGifts: _showGifts, onShop: _showBackgroundStore,
                  onTools: _showToolsGrid, onCaptions: _showCaptionSettings,
                  micIcon: isPublishing
                    ? (_controller.muted || !_controller.joined ? Icons.mic_off_rounded : Icons.mic_rounded)
                    : Icons.pan_tool_alt_rounded,
                  micLabel: isPublishing
                      ? (_me?.forcedMuted == true
                          ? label('كتم المضيف', 'Muted by host')
                          : label('الميكروفون', 'Microphone'))
                      : label('رفع اليد', 'Raise hand'),
                  onMic: !_controller.joined || _micBusy ||
                          _me?.forcedMuted == true || !isPublishing
                      ? null : _toggleMicSafely,
                  )),
                  if (MediaQuery.viewInsetsOf(context).bottom == 0 &&
                      _me != null && (_canModerate || !isPublishing))
                    Positioned(
                      left: 10,
                      bottom: 79,
                      child: _buildHandControl(isArabic, isPublishing),
                    ),
                ])),
              ]);
            })),
          ])),
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
  const _TeacherAiCompactSeat({
    required this.configured,
    this.note,
    this.onTap,
  });

  final bool configured;
  final RoomTeacherAiNote? note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final correction = note?.correction.trim() ?? '';
    final pronunciation = note?.pronunciationTip?.trim() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF6DE7C0).withValues(alpha: .50),
            ),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 23,
                backgroundColor: Color(0xFF3A2D71),
                child: Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Teacher AI',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      correction.isNotEmpty
                          ? correction
                          : configured
                              ? 'Tap to ask • listening for corrections…'
                              : 'AI backend connection required',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: correction.isNotEmpty
                            ? const Color(0xFF8EEAD0)
                            : Colors.white60,
                        fontSize: 10,
                        height: 1.2,
                      ),
                    ),
                    if (pronunciation.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        pronunciation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFD66B),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                ),
            ],
          ),
        ),
      ),
    );
  }
}