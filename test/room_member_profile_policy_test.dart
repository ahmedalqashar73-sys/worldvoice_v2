import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/room_stage_models.dart';
import 'package:worldvoice/features/rooms/data/room_moderation_models.dart';
import 'package:worldvoice/features/rooms/presentation/room_member_profile_policy.dart';

void main() {
  test('all human roles use the same real participant for profile cards', () {
    for (final role in [RoomMemberRole.host, RoomMemberRole.coHost,
      RoomMemberRole.speaker, RoomMemberRole.listener, RoomMemberRole.vipSeat]) {
      final member = RoomParticipant(userId:'user',displayName:'User',role:role,
        handRaised:false,isModerator:true);
      expect(roomProfileForSeat(RoomSeatState(index:1,role:role,userId:'user'),
        [member],'host'),same(member));
    }
  });
  test('reserved host opens profile without microphone or moderation presence', () {
    const seat = RoomSeatState(index:1,role:RoomMemberRole.host,userId:'host',
      displayName:'Host',frameId:'free_soft_green');
    final profile = roomProfileForSeat(seat, [], 'host');
    expect(profile?.userId, 'host');
    expect(profile?.frameId, 'free_soft_green');
    expect(profile?.agoraUid, isNull);
    expect(roomProfileForSeat(seat, [], 'someone-else'), isNull);
  });
}
