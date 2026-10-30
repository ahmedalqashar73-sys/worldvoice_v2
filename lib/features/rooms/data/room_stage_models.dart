enum RoomMemberRole {
  host,
  coHost,
  speaker,
  vipSeat,
  listener,
  teacherAi,
}

extension RoomMemberRoleLabel on RoomMemberRole {
  String get label {
    switch (this) {
      case RoomMemberRole.host:
        return 'Host';
      case RoomMemberRole.coHost:
        return 'Co-host';
      case RoomMemberRole.speaker:
        return 'Speaker';
      case RoomMemberRole.vipSeat:
        return 'VIP';
      case RoomMemberRole.listener:
        return 'Listener';
      case RoomMemberRole.teacherAi:
        return 'Teacher AI';
    }
  }
}

class RoomSeatState {
  const RoomSeatState({
    required this.index,
    required this.role,
    this.userId,
    this.displayName,
    this.avatarUrl,
    this.frameId,
    this.agoraUid,
    this.isMuted = false,
    this.isActiveSpeaker = false,
    this.frameLevel = 0,
    this.giftFrameLevel = 0,
    this.isLocalUser = false,
  });

  final int index;
  final RoomMemberRole role;
  final String? userId;
  final String? displayName;
  final String? avatarUrl;
  final String? frameId;
  final int? agoraUid;
  final bool isMuted;
  final bool isActiveSpeaker;
  final int frameLevel;
  final int giftFrameLevel;
  final bool isLocalUser;

  bool get isEmpty =>
      displayName == null && agoraUid == null && role != RoomMemberRole.teacherAi;

  RoomSeatState copyWith({
    RoomMemberRole? role,
    String? userId,
    String? displayName,
    String? avatarUrl,
    String? frameId,
    int? agoraUid,
    bool? isMuted,
    bool? isActiveSpeaker,
    int? frameLevel,
    int? giftFrameLevel,
    bool? isLocalUser,
  }) {
    return RoomSeatState(
      index: index,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      frameId: frameId ?? this.frameId,
      agoraUid: agoraUid ?? this.agoraUid,
      isMuted: isMuted ?? this.isMuted,
      isActiveSpeaker: isActiveSpeaker ?? this.isActiveSpeaker,
      frameLevel: frameLevel ?? this.frameLevel,
      giftFrameLevel: giftFrameLevel ?? this.giftFrameLevel,
      isLocalUser: isLocalUser ?? this.isLocalUser,
    );
  }
}

/// Visual-only reserved host seat. When the host leaves and a moderator keeps
/// the room open, Firestore deletes the host's participant presence, but room
/// ownership remains the same. Never mistake this placeholder for a connected
/// Agora speaker or an active moderator.
RoomSeatState reserveAbsentHostSeat(
  RoomSeatState seat, {
  required bool roomIsOpen,
  required String? hostId,
  required String? hostName,
  String? hostPhotoUrl,
  String? hostFrameId,
}) {
  if (!roomIsOpen || !seat.isEmpty || seat.index != 1 ||
      hostId == null || hostId.trim().isEmpty) {
    return seat;
  }
  final name = hostName?.trim();
  return RoomSeatState(
    index: 1,
    role: RoomMemberRole.host,
    userId: hostId,
    displayName: name == null || name.isEmpty ? 'Host' : name,
    avatarUrl: hostPhotoUrl,
    frameId: hostFrameId,
    isMuted: true,
    isActiveSpeaker: false,
    isLocalUser: false,
  );
}
