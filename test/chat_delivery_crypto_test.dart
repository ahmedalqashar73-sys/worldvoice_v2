import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:cryptography/cryptography.dart';
import 'package:worldvoice/features/chat/services/chat_delivery_crypto.dart';

void main() {
  test(
    'only recipient decrypts; moved, tampered and wrong-chat chunks fail',
    () async {
      final alice = await ChatDeliveryCrypto.agreement.newKeyPair();
      final bob = await ChatDeliveryCrypto.agreement.newKeyPair();
      final stranger = await ChatDeliveryCrypto.agreement.newKeyPair();
      Future<String> public(KeyPair key) async =>
          base64Encode((await key.extractPublicKey() as SimplePublicKey).bytes);
      final sending = await ChatDeliveryCrypto.derive(
        alice,
        await public(bob),
        'chat/envelope',
      );
      final receiving = await ChatDeliveryCrypto.derive(
        bob,
        await public(alice),
        'chat/envelope',
      );
      final bytes = utf8.encode('رسالة خاصة وصورة وفيديو');
      final encrypted = await ChatDeliveryCrypto.seal(
        bytes,
        sending,
        'chat/envelope/0',
      );
      expect(
        await ChatDeliveryCrypto.open(encrypted, receiving, 'chat/envelope/0'),
        bytes,
      );
      expect(jsonEncode(encrypted), isNot(contains('رسالة')));
      await expectLater(
        ChatDeliveryCrypto.open(encrypted, receiving, 'chat/envelope/1'),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
      final foreign = await ChatDeliveryCrypto.derive(
        stranger,
        await public(alice),
        'chat/envelope',
      );
      await expectLater(
        ChatDeliveryCrypto.open(encrypted, foreign, 'chat/envelope/0'),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
      final otherChat = await ChatDeliveryCrypto.derive(
        bob,
        await public(alice),
        'other/envelope',
      );
      await expectLater(
        ChatDeliveryCrypto.open(encrypted, otherChat, 'chat/envelope/0'),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
      final corrupted = {
        ...encrypted,
        'mac': base64Encode(List<int>.filled(16, 0)),
      };
      await expectLater(
        ChatDeliveryCrypto.open(corrupted, receiving, 'chat/envelope/0'),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    },
  );
}
