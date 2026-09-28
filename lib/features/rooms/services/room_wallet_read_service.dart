import 'package:cloud_firestore/cloud_firestore.dart';

/// Staged migration switch: disabled in all ordinary builds. A release must
/// enable this ONLY after legacy balances are migrated, server credit/debit
/// paths use private wallets, all UI readers are updated, and Firestore rules
/// stop other members from reading financial fields.
class RoomWalletReadService {
  const RoomWalletReadService._();

  static const bool privateWalletCutover = bool.fromEnvironment(
    'WORLDVOICE_PRIVATE_WALLETS_ENABLED',
    defaultValue: false,
  );

  static Stream<DocumentSnapshot<Map<String, dynamic>>> watchOwnWallet(
    String uid,
  ) {
    final user = FirebaseFirestore.instance.collection('users').doc(uid);
    return privateWalletCutover
        ? user.collection('private').doc('wallet').snapshots()
        : user.snapshots();
  }
}
