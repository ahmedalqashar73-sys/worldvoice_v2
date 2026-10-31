import '../data/room_moderation_models.dart';
import '../data/room_stage_models.dart';

/// A reserved host avatar may open a profile without claiming live presence.
/// This value is presentation-only and never added to room participants.
RoomParticipant? roomProfileForSeat(RoomSeatState seat,
    Iterable<RoomParticipant> participants, String? hostId) {
  final id = seat.userId;
  if (id == null || id.isEmpty || seat.role == RoomMemberRole.teacherAi) {
    return null;
  }
  for (final member in participants) {
    if (member.userId == id) return member;
  }
  if (id != hostId || seat.role != RoomMemberRole.host) return null;
  return RoomParticipant(userId: id,
    displayName: seat.displayName ?? 'WorldVoice',
    photoUrl: seat.avatarUrl, frameId: seat.frameId,
    role: RoomMemberRole.host, handRaised: false);
}
