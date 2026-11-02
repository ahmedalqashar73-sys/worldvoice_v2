/// Keeps the permanent host at seat 1 and packs speakers from seat 2.
/// A sort by the previous seat makes everyone see a stable order.
List<T> compactStageSeats<T>({
  required List<T> participants,
  required String? Function(T) roleOf,
  required int? Function(T) seatOf,
  required String Function(T) idOf,
  required T Function(T, int) withSeat,
}) {
  final speakers = participants.where((p) {
    final role = roleOf(p);
    return role == 'speaker' || role == 'coHost' || role == 'vipSeat';
  }).toList()
    ..sort((a, b) {
      final n = (seatOf(a) ?? 999).compareTo(seatOf(b) ?? 999);
      return n != 0 ? n : idOf(a).compareTo(idOf(b));
    });
  final result = <T>[];
  var next = 2;
  for (final participant in participants) {
    if (roleOf(participant) == 'host') {
      result.add(withSeat(participant, 1));
    } else if (!speakers.any((p) => idOf(p) == idOf(participant))) {
      result.add(participant);
    }
  }
  for (final person in speakers) {
    result.add(withSeat(person, next > 8 ? 8 : next++));
  }
  return result;
}
