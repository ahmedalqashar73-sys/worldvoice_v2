import 'package:flutter/material.dart';

import '../../profile/presentation/world_bond_screen.dart';

/// Only used beside the message author in voice-room chat. Does NOT alter
/// user profiles, DM, Home comments or the existing VIP/gift-level marks.
class RoomBondChatMarks extends StatefulWidget {
  const RoomBondChatMarks({required this.userId, super.key});
  final String userId;

  @override
  State<RoomBondChatMarks> createState() => _RoomBondChatMarksState();
}

class _RoomBondChatMarksState extends State<RoomBondChatMarks> {
  static final _cache = <String, ({DateTime at, Future<Map<String, dynamic>> result})>{};
  static final ValueNotifier<int> _revision = ValueNotifier<int>(0);
  static String? _invalidatedUser;

  /// Refresh room-chat badges immediately after a WorldBond relation changes,
  /// rather than waiting for the read cache to expire on the next comment.
  static void invalidateUser(String? userId) {
    if (userId == null || userId.isEmpty) return;
    _cache.remove(userId);
    _invalidatedUser = userId;
    _revision.value += 1;
  }

  Future<Map<String, dynamic>>? _details;

  void _handleInvalidation() {
    if (!mounted || _invalidatedUser != widget.userId) return;
    setState(() => _details = _fetch(widget.userId));
  }

  Future<Map<String, dynamic>> _fetch(String id) {
    final cached = _cache[id];
    if (cached != null &&
        DateTime.now().difference(cached.at) < const Duration(seconds: 90)) {
      return cached.result;
    }
    // Reuse one request for all visible messages from the same author.
    final request = WorldBondApi.request(
      'world-bond/chat-badges?userId=${Uri.encodeQueryComponent(id)}',
    );
    _cache[id] = (at: DateTime.now(), result: request);
    if (_cache.length > 80) {
      _cache.remove(_cache.keys.first);
    }
    return request;
  }

  @override
  void initState() {
    super.initState();
    _revision.addListener(_handleInvalidation);
    if (widget.userId.isNotEmpty) _details = _fetch(widget.userId);
  }

  @override
  void dispose() {
    _revision.removeListener(_handleInvalidation);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RoomBondChatMarks oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _details = widget.userId.isEmpty ? null : _fetch(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_details == null) return const SizedBox.shrink();
    return FutureBuilder<Map<String, dynamic>>(
      future: _details,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.hasError) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data?['badges'];
        if (data is! Map) return const SizedBox.shrink();
        const designs = <(String, String, IconData, Color)>[
          ('learning', 'رفيق التعلّم', Icons.menu_book_rounded,
            Color(0xFF2CC795)),
          ('language', 'رفيق اللغة', Icons.translate_rounded,
            Color(0xFF66D5F1)),
          ('friend', 'صديق مميز', Icons.star_rounded,
            Color(0xFFC199FF)),
          ('duo', 'ثنائي مميز', Icons.favorite_rounded,
            Color(0xFFFFCB87)),
        ];
        return Wrap(
          key: const ValueKey('room-chat-worldbond-badges'),
          spacing: 3, runSpacing: 3,
          children: [
            for (final item in designs)
              if (((data[item.$1] as num?)?.toInt() ?? 0) > 0)
                Tooltip(
                  message: '${item.$2} · LV${data[item.$1]}',
                  child: Container(
                    key: ValueKey('room-chat-bond-${item.$1}'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(colors: [
                        item.$4.withValues(alpha: .65),
                        const Color(0xFF17372D),
                      ]),
                      border: Border.all(color: item.$4),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(item.$3, size: 12, color: Colors.white),
                      const SizedBox(width: 2),
                      Text('LV${data[item.$1]}',
                        style: const TextStyle(fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w900)),
                    ]),
                  ),
                ),
          ],
        );
      },
    );
  }
}
