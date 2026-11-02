import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/compact_stage_seats.dart';

class _Speaker {
  const _Speaker(this.id, this.role, this.seat);
  final String id;
  final String role;
  final int? seat;

  _Speaker at(int index) => _Speaker(id, role, index);
}

List<_Speaker> arrange(List<_Speaker> members) =>
    compactStageSeats<_Speaker>(
      participants: members,
      roleOf: (m) => m.role,
      seatOf: (m) => m.seat,
      idOf: (m) => m.id,
      withSeat: (m, i) => m.at(i),
    );

void main() {
  test('when seat 2 exits, speakers from 3 and 4 shift forward', () {
    final members = arrange([
      const _Speaker('host', 'host', 1),
      const _Speaker('A', 'speaker', 3),
      const _Speaker('B', 'coHost', 4),
      const _Speaker('L', 'listener', null),
    ]);
    expect(members.where((m) => m.role != 'listener')
        .map((m) => [m.id, m.seat]).toList(), [
      ['host', 1],
      ['A', 2],
      ['B', 3],
    ]);
    expect(members.firstWhere((m) => m.id == 'L').seat, null);
  });

  test('eight filled seats: fifth exit shifts sixth to fifth', () {
    final seats = arrange([
      const _Speaker('host', 'host', 1),
      const _Speaker('s2', 'speaker', 2),
      const _Speaker('s3', 'speaker', 3),
      const _Speaker('s4', 'speaker', 4),
      const _Speaker('s6', 'speaker', 6),
      const _Speaker('s7', 'vipSeat', 7),
      const _Speaker('s8', 'coHost', 8),
    ]);
    expect(
      {for (final m in seats) m.id: m.seat},
      {'host': 1, 's2': 2, 's3': 3, 's4': 4,
        's6': 5, 's7': 6, 's8': 7},
    );
  });

  test('compaction remains stable after it is applied twice', () {
    final first = arrange([
      const _Speaker('host', 'host', 1),
      const _Speaker('B', 'speaker', 5),
      const _Speaker('A', 'speaker', 5),
    ]);
    final second = arrange(first);
    expect(second.map((m) => [m.id, m.seat]).toList(),
      first.map((m) => [m.id, m.seat]).toList());
  });
}
