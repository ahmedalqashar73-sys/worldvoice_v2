import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/live/data/live_gift_playback_queue.dart';

void main() {
  test('first empty snapshot does not swallow the first new gift', () {
    final queue = LiveGiftPlaybackQueue<String>((id) => id);
    queue.ingestSnapshot(const <String>[]);
    queue.ingestSnapshot(['gift-1']);
    expect(queue.takeNext(), 'gift-1');
    expect(queue.takeNext(), isNull);
  });

  test('existing gifts are not replayed when a viewer joins', () {
    final queue = LiveGiftPlaybackQueue<String>((id) => id);
    queue.ingestSnapshot(['old-2', 'old-1']);
    expect(queue.pendingCount, 0);
    queue.ingestSnapshot(['new-3', 'old-2', 'old-1']);
    expect(queue.takeNext(), 'new-3');
    expect(queue.takeNext(), isNull);
  });

  test('simultaneous gifts are queued oldest first without duplication', () {
    final queue = LiveGiftPlaybackQueue<String>((id) => id);
    queue.ingestSnapshot(const <String>[]);
    queue.ingestSnapshot(['gift-3', 'gift-2', 'gift-1']);
    queue.ingestSnapshot(['gift-4', 'gift-3', 'gift-2', 'gift-1']);
    expect(
      [queue.takeNext(), queue.takeNext(), queue.takeNext(),
        queue.takeNext(), queue.takeNext()],
      ['gift-1', 'gift-2', 'gift-3', 'gift-4', null],
    );
  });

  test('long burst is bounded and reset supports a new Live', () {
    final queue = LiveGiftPlaybackQueue<String>(
      (id) => id, maxPending: 2,
    );
    queue.ingestSnapshot(const <String>[]);
    queue.ingestSnapshot(['3', '2', '1']);
    expect(queue.pendingCount, 2);
    expect(queue.takeNext(), '1');
    expect(queue.takeNext(), '2');
    queue.clear();
    queue.ingestSnapshot(const <String>[]);
    queue.ingestSnapshot(['1']);
    expect(queue.takeNext(), '1');
  });
}
