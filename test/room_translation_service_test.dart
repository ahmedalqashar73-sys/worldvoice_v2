import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/services/room_translation_service.dart';

void main() {
  final service = RoomTranslationService(roomId: 'test-room');

  test('same-language Arabic speech does not get mislabeled English', () {
    expect(
      service.guessSourceCode(
        'مرحبا كيف حالك',
        targetCode: 'ar',
        fallbackSourceCode: 'en',
      ),
      'ar',
    );
  });

  test('detects Japanese speech even with a conflicting room hint', () {
    expect(
      service.guessSourceCode(
        'ありがとう',
        targetCode: 'en',
        fallbackSourceCode: 'ar',
      ),
      'ja',
    );
  });

  test('falls back to source language for Latin-script languages', () {
    expect(
      service.guessSourceCode(
        'Hola amigo',
        targetCode: 'ar',
        fallbackSourceCode: 'es',
      ),
      'es',
    );
    expect(
      service.guessSourceCode('Hello', targetCode: 'es'),
      'en',
    );
  });
}
