import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Agora Live channel ownership is bound to the authenticated Firebase UID.
/// The Worker verifies this prefix only for host publishing; all guest
/// publishing and audience subscriptions still require Firestore membership.
String liveHostChannelPrefix(String firebaseUid) {
  if (firebaseUid.isEmpty) {
    throw ArgumentError.value(firebaseUid, 'firebaseUid', 'Sign-in required');
  }
  return 'live_${sha256.convert(utf8.encode(firebaseUid)).toString().substring(0, 24)}_';
}

/// Generates a new owner-scoped Live channel. No user information is stored
/// in the ID; the random nonce prevents reuse of the previous broadcast.
String newLiveHostChannel(String firebaseUid) {
  final nonce = DateTime.now().microsecondsSinceEpoch.toRadixString(16) +
      Random.secure().nextInt(0x7fffffff).toRadixString(16).padLeft(8, '0');
  return '${liveHostChannelPrefix(firebaseUid)}$nonce';
}
