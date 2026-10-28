import 'dart:convert';
import 'package:cryptography/cryptography.dart';

/// Only authenticated ciphertext leaves the device. Each envelope and chunk
/// has its own authenticated context; moving chunks between chats fails closed.
class ChatDeliveryCrypto {
  static final agreement = X25519();
  static final cipher = AesGcm.with256bits();

  static Future<SecretKey> derive(
    KeyPair own,
    String peerPublic,
    String context,
  ) async {
    final shared = await agreement.sharedSecretKey(
      keyPair: own,
      remotePublicKey: SimplePublicKey(
        base64Decode(peerPublic),
        type: KeyPairType.x25519,
      ),
    );
    return Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
      secretKey: shared,
      info: utf8.encode('worldvoice-delivery-v1:$context'),
      nonce: const [],
    );
  }

  static Future<Map<String, dynamic>> seal(
    List<int> bytes,
    SecretKey key,
    String context,
  ) async {
    final box = await cipher.encrypt(
      bytes,
      secretKey: key,
      aad: utf8.encode(context),
    );
    return {
      'cipher': base64Encode(box.cipherText),
      'nonce': base64Encode(box.nonce),
      'mac': base64Encode(box.mac.bytes),
    };
  }

  static Future<List<int>> open(
    Map<String, dynamic> data,
    SecretKey key,
    String context,
  ) => cipher.decrypt(
    SecretBox(
      base64Decode(data['cipher'] as String),
      nonce: base64Decode(data['nonce'] as String),
      mac: Mac(base64Decode(data['mac'] as String)),
    ),
    secretKey: key,
    aad: utf8.encode(context),
  );
}
