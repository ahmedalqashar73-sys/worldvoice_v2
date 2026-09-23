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
  });

  final String userId;
  final String displayName;
  final String? photoUrl;
  final RoomMemberRole role;
  final bool handRaised;
  final int? agoraUid;
  final int? seatIndex;
  final int? requestedSeatIndex;

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
