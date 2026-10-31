import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/presentation/voice_rooms_list.dart';

void main() {
  test('missing Firestore data is loading, not an empty room list', () {
    expect(
      resolveRoomsDataState(
        hasError: false, hasData: false, waiting: true,
        isFromCache: false, visibleRooms: 0,
      ),
      RoomsDataState.loading,
    );
  });

  test('Firestore unavailable without a snapshot shows a connection error', () {
    expect(
      resolveRoomsDataState(
        hasError: true, hasData: false, waiting: false,
        isFromCache: false, visibleRooms: 0,
      ),
      RoomsDataState.error,
    );
  });

  test('empty offline cache cannot be displayed as no open rooms', () {
    expect(
      resolveRoomsDataState(
        hasError: false, hasData: true, waiting: false,
        isFromCache: true, visibleRooms: 0,
      ),
      RoomsDataState.cached,
    );
  });

  test('cached room cards stay available even after a network error', () {
    expect(
      resolveRoomsDataState(
        hasError: true, hasData: true, waiting: false,
        isFromCache: true, visibleRooms: 2,
      ),
      RoomsDataState.cached,
    );
  });

  test('only a confirmed server snapshot may report no rooms', () {
    expect(
      resolveRoomsDataState(
        hasError: false, hasData: true, waiting: false,
        isFromCache: false, visibleRooms: 0,
      ),
      RoomsDataState.empty,
    );
    expect(
      resolveRoomsDataState(
        hasError: false, hasData: true, waiting: false,
        isFromCache: false, visibleRooms: 1,
      ),
      RoomsDataState.ready,
    );
  });
}
