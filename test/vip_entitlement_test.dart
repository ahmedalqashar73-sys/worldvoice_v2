import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/core/vip/vip_entitlement.dart';

void main() {
  final now = DateTime.utc(2026, 10, 21, 12);

  test('free accounts and a tier label cannot unlock VIP', () {
    expect(VipEntitlement.isActive(null, now: now), isFalse);
    expect(VipEntitlement.isActive({}, now: now), isFalse);
    expect(VipEntitlement.isActive({'isVip': false}, now: now), isFalse);
    expect(VipEntitlement.isActive({'vipTier': 'gold'}, now: now), isFalse);
  });

  test('legacy/admin VIP with no expiry remains active', () {
    expect(VipEntitlement.isActive({'isVip': true}, now: now), isTrue);
  });

  test('Firestore expiry must be in the future', () {
    expect(VipEntitlement.isActive({
      'isVip': true,
      'vipExpiresAt': Timestamp.fromDate(now.add(const Duration(days: 1))),
    }, now: now), isTrue);
    expect(VipEntitlement.isActive({
      'isVip': true,
      'vipExpiresAt': Timestamp.fromDate(now),
    }, now: now), isFalse);
    expect(VipEntitlement.isActive({
      'isVip': true,
      'vipExpiresAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
    }, now: now), isFalse);
  });

  test('invalid expiry fails closed', () {
    expect(VipEntitlement.isActive({
      'isVip': true,
      'vipExpiresAt': 'invalid',
    }, now: now), isFalse);
    expect(VipEntitlement.isActive({
      'isVip': true,
      'vipExpiresAt': 999999999,
    }, now: now), isFalse);
    expect(VipEntitlement.isActive({
      'isVip': true,
      'vipExpiresAt': now.add(const Duration(minutes: 1)).toIso8601String(),
    }, now: now), isTrue);
  });
}
