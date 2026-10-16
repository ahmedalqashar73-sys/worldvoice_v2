import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Live room game board: always within the room, below the eight seats and
/// above the listener strip. The chat bar handles private submissions.
class RoomGameInlineBoard extends StatefulWidget {
  const RoomGameInlineBoard({
    required this.status,
    required this.isArabic,
    this.onOpenGames,
    super.key,
  });
  final Map<String, dynamic> status;
  final bool isArabic;
  final VoidCallback? onOpenGames;

  @override
  State<RoomGameInlineBoard> createState() => _RoomGameInlineBoardState();
}

class _RoomGameInlineBoardState extends State<RoomGameInlineBoard> {
  Timer? _clock;
  DateTime _receivedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.status['active'] == true) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant RoomGameInlineBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.status, widget.status)) {
      _receivedAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  int get _remaining => math.max(0,
    ((widget.status['secondsLeft'] as num?)?.toInt() ?? 0) -
        DateTime.now().difference(_receivedAt).inSeconds);

  @override
  Widget build(BuildContext context) {
    final data = widget.status;
    final ar = widget.isArabic;
    final active = data['active'] == true;
    final finished = data['finished'] == true;
    final isGuess = data['mode'] == 'guess';
    final question = data['question'] as Map?;
    final index = (data['questionIndex'] as num?)?.toInt() ?? 0;
    final leaderboard = (data['leaderboard'] as List?) ?? const [];
    if (!active && !finished) return const SizedBox.shrink();

    final title = isGuess
        ? (ar ? 'خمّن الكلمة' : 'Guess the Word')
        : (ar ? 'المفردات' : 'Vocabulary');
    return Container(
      key: const ValueKey<String>('room-inline-games-board'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF123B30).withValues(alpha: .96),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFF538267), width: .8),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const Icon(Icons.sports_esports_rounded,
              size: 17, color: Color(0xFFEFCB78)),
          const SizedBox(width: 6),
          Expanded(child: Text(title,
            style: const TextStyle(color: Color(0xFFF1D58B),
                fontWeight: FontWeight.w900, fontSize: 13))),
          if (active)
            Text((index + 1).toString() + '/5 • ' + _remaining.toString() + 's',
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Colors.white,
                  fontSize: 12, fontWeight: FontWeight.w800))
          else
            Text(ar ? 'النتائج النهائية' : 'Final results',
              style: const TextStyle(color: Color(0xFFF1D58B),
                  fontWeight: FontWeight.w700, fontSize: 12)),
          if (widget.onOpenGames != null)
            InkWell(
              onTap: widget.onOpenGames,
              child: const Padding(
                padding: EdgeInsetsDirectional.only(start: 9),
                child: Icon(Icons.settings_outlined,
                  color: Color(0xFFEFCB78), size: 20),
              ),
            ),
        ]),
        if (active) ...[
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: _remaining / 30,
            minHeight: 3,
            backgroundColor: const Color(0xFF28624C),
            color: const Color(0xFFE4C270)),
          const SizedBox(height: 9),
          Text(question?['clue']?.toString() ?? '',
            key: const ValueKey<String>('room-inline-game-question'),
            textAlign: TextAlign.center,
            textDirection: data['language'] == 'ar'
                ? TextDirection.rtl : TextDirection.ltr,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white,
              fontSize: 16, fontWeight: FontWeight.w800, height: 1.35)),
          const SizedBox(height: 7),
          Text(
            data['canAnswer'] == true
                ? data['answered'] == true
                    ? (ar ? 'تم تسجيل إجابتك • انتظر الكلمة التالية'
                        : 'Answer submitted • next word soon')
                    : (ar ? 'اكتب إجابتك في شريط الشات بالأسفل'
                        : 'Type your answer in the chat bar below')
                : (ar ? 'يمكنك مشاهدة الجولة • التخمين للمسرح فقط'
                    : 'Watch the game • stage members can guess'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFBBD5C4), fontSize: 11)),
        ] else ...[
          const SizedBox(height: 8),
          if (leaderboard.isEmpty)
            Text(ar ? 'لم تسجل أي إجابات' : 'No scores yet',
              style: const TextStyle(color: Colors.white70))
          else
            Row(children: [
              for (var i = 0; i < math.min(3, leaderboard.length); i++)
                Expanded(child: Column(children: [
                  Text(['🥇', '🥈', '🥉'][i],
                    style: const TextStyle(fontSize: 23)),
                  Text((leaderboard[i] as Map)['name']?.toString() ?? 'WorldVoice',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 12)),
                  Text(((leaderboard[i] as Map)['points'] ?? 0).toString() +
                      ' pts',
                    style: const TextStyle(color: Color(0xFFE7C783),
                      fontSize: 11)),
                ])),
            ]),
        ],
      ]),
    );
  }
}
