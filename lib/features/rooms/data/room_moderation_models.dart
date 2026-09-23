import 'room_stage_models.dart';

class RoomParticipant {
  const RoomParticipant({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.handRaised,
    this.photoUrl,
    this.agoraUid,
    this.seatIndex,
    this.requestedSeatIndex,
    this.isModerator = false,
    this.warningCount = 0,
    this.forcedMuted = false,
    this.kicked = false,
    this.speakingSeconds = 0,
  });

  final String userId;
  final String displayName;
  final String? photoUrl;
  final RoomMemberRole role;
  final bool handRaised;
  final int? agoraUid;
  final int? seatIndex;
  final int? requestedSeatIndex;
  final bool isModerator;
  final int warningCount;
  final bool forcedMuted;
  final bool kicked;
  final int speakingSeconds;

  bool get canModerate =>
      role == RoomMemberRole.host || isModerator;

  bool get isOnStage =>
      role == RoomMemberRole.host ||
      role == RoomMemberRole.coHost ||
      role == RoomMemberRole.speaker ||
      role == RoomMemberRole.vipSeat;

  static RoomMemberRole roleFromString(String? value) {
    switch (value) {
      case 'host':
        return RoomMemberRole.host;
      case 'coHost':
        return RoomMemberRole.coHost;
      case 'vipSeat':
        return RoomMemberRole.vipSeat;
      case 'speaker':
        return RoomMemberRole.speaker;
      default:
        return RoomMemberRole.listener;
    }
  }

  static String roleToString(RoomMemberRole role) {
    switch (role) {
      case RoomMemberRole.host:
        return 'host';
      case RoomMemberRole.coHost:
        return 'coHost';
      case RoomMemberRole.vipSeat:
        return 'vipSeat';
      case RoomMemberRole.speaker:
        return 'speaker';
      case RoomMemberRole.listener:
        return 'listener';
      case RoomMemberRole.teacherAi:
        return 'teacherAi';
    }
  }
}
