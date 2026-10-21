import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/services/room_quota_service.dart';
import 'package:worldvoice/features/rooms/services/vip_room_features.dart';

void main() {
  test('Free host has 4h, free guest has 2h and 3h ad extension', () {
    expect(RoomTimeAllowance.freeLimit(asHost:true,adBonusSeconds:0),14400);
    expect(RoomTimeAllowance.freeLimit(asHost:false,adBonusSeconds:0),7200);
    expect(RoomTimeAllowance.freeLimit(asHost:false,adBonusSeconds:3*3600),
        5*3600);
    expect(RoomTimeAllowance.freeLimit(asHost:false,adBonusSeconds:7*3600),
        5*3600);
    expect(RoomTimeAllowance.freeLimit(asHost:true,adBonusSeconds:3*3600),
        4*3600);
  });

  test('Only verified active VIP profile bypasses quotas and paid room AI', () {
    final now=DateTime.utc(2026,10,21,12);
    expect(VipRoomFeatures.activeVip(null,now),false);
    expect(VipRoomFeatures.activeVip(<String,dynamic>{'isVip':false},now),false);
    expect(VipRoomFeatures.activeVip(<String,dynamic>{'isVip':true},now),true);
    expect(VipRoomFeatures.activeVip(<String,dynamic>{
      'isVip':true,
      'vipExpiresAt':Timestamp.fromDate(now.add(const Duration(days:1))),
    },now),true);
    expect(VipRoomFeatures.activeVip(<String,dynamic>{
      'isVip':true,
      'vipExpiresAt':Timestamp.fromDate(now.subtract(const Duration(seconds:1))),
    },now),false);
    expect(VipRoomFeatures.activeVip(<String,dynamic>{
      'isVip':true,
      'vipExpiresAt':now,
    },now),false);
  });

  test('Unlimited VIP status returns unlimited remaining room time',(){
    const status=RoomQuotaStatus(
      allowed:true,usedSeconds:0,limitSeconds:0,
      adsWatched:0,adBonusSeconds:0,isUnlimited:true);
    expect(status.remainingSeconds,greaterThan(4*3600));
    expect(status.allowed,isTrue);
  });
}
