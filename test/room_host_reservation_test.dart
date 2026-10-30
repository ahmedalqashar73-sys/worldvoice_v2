import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/room_stage_models.dart';

void main() {
  test('offline host keeps their portrait in seat 1 while room is open', () {
    const first = RoomSeatState(index: 1, role: RoomMemberRole.speaker);
    final reserved = reserveAbsentHostSeat(
      first,
      roomIsOpen: true,
      hostId: 'owner_123',
      hostName: 'Ahmed',
      hostPhotoUrl: 'https://example.com/owner.png',
      hostFrameId: 'frame__golden_crown',
    );
    expect(reserved.isEmpty, isFalse);
    expect(reserved.index, 1);
    expect(reserved.role, RoomMemberRole.host);
    expect(reserved.displayName, 'Ahmed');
    expect(reserved.avatarUrl, 'https://example.com/owner.png');
    expect(reserved.frameId, 'frame__golden_crown');
    expect(reserved.isMuted, isTrue);
    expect(reserved.agoraUid, isNull);
    expect(reserved.isActiveSpeaker, isFalse);
    expect(reserved.isLocalUser, isFalse);
  });

  test('never replace a real occupied stage seat', () {
    const participant = RoomSeatState(
      index: 1,
      role: RoomMemberRole.host,
      userId: 'owner_123',
      displayName: 'Ahmed',
      agoraUid: 78,
      isMuted: false,
    );
    final actual = reserveAbsentHostSeat(participant,
      roomIsOpen: true, hostId: 'owner_123', hostName: 'Absent');
    expect(identical(actual, participant), isTrue);
    expect(actual.agoraUid, 78);
  });

  test('no ghost host when room was closed or another seat is empty', () {
    const first = RoomSeatState(index: 1, role: RoomMemberRole.speaker);
    const second = RoomSeatState(index: 2, role: RoomMemberRole.speaker);
    expect(reserveAbsentHostSeat(first,
        roomIsOpen: false, hostId: 'owner_123',
        hostName: 'Ahmed').isEmpty, isTrue);
    expect(reserveAbsentHostSeat(second,
        roomIsOpen: true, hostId: 'owner_123',
        hostName: 'Ahmed').isEmpty, isTrue);
    expect(reserveAbsentHostSeat(first,
        roomIsOpen: true, hostId: null,
        hostName: 'Ahmed').isEmpty, isTrue);
  });
}
