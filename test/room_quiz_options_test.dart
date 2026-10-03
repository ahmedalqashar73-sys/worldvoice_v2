import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/services/room_quiz_service.dart';

void main() {
  group('RoomQuizService.normalizedCorrectIndex', () {
    test('retains normal selected option', () {
      expect(
        RoomQuizService.normalizedCorrectIndex(
          ['One', 'Two', 'Three', 'Four'], 2),
        2,
      );
    });

    test('reindexes a correct option after blank entries', () {
      expect(
        RoomQuizService.normalizedCorrectIndex(
          ['A', '', '  ', 'D'], 3),
        1,
      );
    });

    test('does not accept an empty selected correct answer', () {
      expect(
        () => RoomQuizService.normalizedCorrectIndex(
          ['A', '  ', 'C'], 1),
        throwsStateError,
      );
    });

    test('rejects out-of-range correct indices', () {
      expect(
        () => RoomQuizService.normalizedCorrectIndex(['A', 'B'], 2),
        throwsStateError,
      );
    });
  });
}
