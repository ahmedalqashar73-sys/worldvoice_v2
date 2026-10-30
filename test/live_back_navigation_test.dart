import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/live/presentation/live_back_navigation.dart';

void main() {
  test('device Back minimizes a connected Live instead of exiting', () {
    expect(
      viewerLiveBackAction(
        joining: false,
        joinFailed: false,
        leaving: false,
        liveEnded: false,
      ),
      ViewerLiveBackAction.minimize,
    );
  });

  test('explicit Leave Live allows the viewer route to pop', () {
    expect(
      viewerLiveBackAction(
        joining: false,
        joinFailed: false,
        leaving: true,
        liveEnded: false,
      ),
      ViewerLiveBackAction.pop,
    );
  });

  test('a real host-ended Firestore session allows leaving', () {
    expect(
      viewerLiveBackAction(
        joining: false,
        joinFailed: false,
        leaving: false,
        liveEnded: true,
      ),
      ViewerLiveBackAction.pop,
    );
  });

  test('connection screen and failed connection may still close', () {
    for (final (joining, joinFailed) in [
      (true, false),
      (false, true),
    ]) {
      expect(
        viewerLiveBackAction(
          joining: joining,
          joinFailed: joinFailed,
          leaving: false,
          liveEnded: false,
        ),
        ViewerLiveBackAction.pop,
      );
    }
  });
}
