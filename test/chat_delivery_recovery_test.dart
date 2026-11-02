import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/chat/services/chat_delivery_service.dart';

void main() {
  test('ready ciphertext is reusable when public keys are unchanged', () {
    expect(
      ChatDeliverySession.readyEnvelopeUsesStaleKeys(
        const {
          'state': 'ready',
          'senderKey': 'sender-v1',
          'recipientKey': 'recipient-v1',
        },
        senderPublicKey: 'sender-v1',
        recipientPublicKey: 'recipient-v1',
      ),
      isFalse,
    );
  });

  test('recipient reinstall requires a fresh encrypted delivery envelope', () {
    expect(
      ChatDeliverySession.readyEnvelopeUsesStaleKeys(
        const {
          'state': 'ready',
          'senderKey': 'sender-v1',
          'recipientKey': 'recipient-v1',
        },
        senderPublicKey: 'sender-v1',
        recipientPublicKey: 'recipient-v2',
      ),
      isTrue,
    );
  });

  test('sender key rotation requires new encrypted delivery envelope', () {
    expect(
      ChatDeliverySession.readyEnvelopeUsesStaleKeys(
        const {
          'state': 'ready',
          'senderKey': 'sender-v1',
          'recipientKey': 'recipient-v1',
        },
        senderPublicKey: 'sender-v2',
        recipientPublicKey: 'recipient-v1',
      ),
      isTrue,
    );
  });

  test('uploading envelope cannot be misclassified as stale ready', () {
    expect(
      ChatDeliverySession.readyEnvelopeUsesStaleKeys(
        const {
          'state': 'uploading',
          'senderKey': 'sender-v1',
          'recipientKey': 'recipient-v1',
        },
        senderPublicKey: 'sender-v2',
        recipientPublicKey: 'recipient-v2',
      ),
      isFalse,
    );
  });
}
