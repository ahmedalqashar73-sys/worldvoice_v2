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
    this.displayName,
    this.avatarUrl,
    this.agoraUid,
    this.isMuted = false,
    this.isActiveSpeaker = false,
    this.frameLevel = 0,
    this.giftFrameLevel = 0,
    this.isLocalUser = false,
  });

  final int index;
  final RoomMemberRole role;
  final String? displayName;
  final String? avatarUrl;
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
    String? displayName,
    String? avatarUrl,
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
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      agoraUid: agoraUid ?? this.agoraUid,
      isMuted: isMuted ?? this.isMuted,
      isActiveSpeaker: isActiveSpeaker ?? this.isActiveSpeaker,
      frameLevel: frameLevel ?? this.frameLevel,
      giftFrameLevel: giftFrameLevel ?? this.giftFrameLevel,
      isLocalUser: isLocalUser ?? this.isLocalUser,
    );
  }
}
