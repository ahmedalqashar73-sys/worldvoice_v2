import 'dart:collection';

/// Shows each newly received Live gift once and in chronological order.
/// The first Firestore snapshot establishes a baseline: old gifts are not
/// animated when someone enters an existing broadcast.
class LiveGiftPlaybackQueue<T> {
  LiveGiftPlaybackQueue(
    this.idOf, {
    this.maxPending = 20,
    this.maxKnown = 160,
  });

  final String Function(T) idOf;
  final int maxPending;
  final int maxKnown;
  final Queue<T> _pending = Queue<T>();
  final Set<String> _known = <String>{};
  bool _primed = false;

  int get pendingCount => _pending.length;

  void ingestSnapshot(Iterable<T> newestFirst) {
    final snapshot = newestFirst.toList(growable: false);
    if (!_primed) {
      _primed = true;
      for (final gift in snapshot) {
        final id = idOf(gift);
        if (id.isNotEmpty) _remember(id);
      }
      return;
    }

    // Firestore streams newest-first. Queue new effects oldest-first so
    // simultaneous gifts do not replace one another on the host/viewers.
    for (final gift in snapshot.reversed) {
      final id = idOf(gift);
      if (id.isEmpty || _known.contains(id)) continue;
      _remember(id);
      if (_pending.length < maxPending) _pending.addLast(gift);
    }
  }

  void _remember(String id) {
    _known.add(id);
    while (_known.length > maxKnown && _known.isNotEmpty) {
      _known.remove(_known.first);
    }
  }

  T? takeNext() => _pending.isEmpty ? null : _pending.removeFirst();

  void clear() {
    _primed = false;
    _known.clear();
    _pending.clear();
  }
}
