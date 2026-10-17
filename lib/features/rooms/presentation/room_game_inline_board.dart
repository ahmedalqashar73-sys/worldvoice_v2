import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Live room game board placed between the two rows of four seats.
/// The chat bar sends private answers; the server chooses the first winner.
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
    final roundLocked = data['roundLocked'] == true;
    final winner = data['winner'] as Map?;
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
            Text('${index + 1}/5 • ${_remaining}s',
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
          if (roundLocked && winner != null)
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(ar ? "الأسرع: ${winner['name'] ?? 'WorldVoice'}"
                      : "First correct: ${winner['name'] ?? 'WorldVoice'}",
                key: const ValueKey('room-game-fastest-winner'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFF5D583),
                    fontSize: 13, fontWeight: FontWeight.w900)),
              Text(ar ? "الإجابة: ${winner['answer'] ?? ''}"
                      : "Answer: ${winner['answer'] ?? ''}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white,
                    fontSize: 12, fontWeight: FontWeight.w700)),
            ])
          else
            Text(
              data['canAnswer'] == true
                  ? data['answered'] == true
                      ? (ar ? 'تم تسجيل إجابتك • انتظر الكلمة التالية'
                          : 'Answer submitted • next word soon')
                      : (ar ? 'اكتب الإجابة في الشات • أول إجابة صحيحة تفوز'
                          : 'Answer in chat • first correct answer wins')
                  : (ar ? 'المفردات للجميع • التخمين للمسرح فقط'
                      : 'Vocabulary for all • Guess is stage-only'),
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
                  Text(ar
                      ? "${(leaderboard[i] as Map)['correctCount'] ?? 0} إجابة صحيحة"
                      : "${(leaderboard[i] as Map)['correctCount'] ?? 0} correct",
                    style: const TextStyle(color: Color(0xFFE7C783),
                      fontSize: 11, fontWeight: FontWeight.w700)),
                  Text("${(leaderboard[i] as Map)['points'] ?? 0} pts",
                    style: const TextStyle(color: Color(0xFFB8D3C2),
                      fontSize: 10)),
                ])),
            ]),
        ],
      ]),
    );
  }
}
