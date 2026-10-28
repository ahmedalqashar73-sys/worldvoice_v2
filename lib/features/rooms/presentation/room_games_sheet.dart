import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/room_quiz_service.dart';

/// Five-word language games: host selects one level for everyone.
/// Server enforces quotas and stage eligibility; listeners can play Vocabulary.
class RoomGamesSheet extends StatefulWidget {
  const RoomGamesSheet({required this.roomId, required this.isHost, this.service, super.key});
  final String roomId;
  final bool isHost;
  final RoomGamesService? service;
  @override
  State<RoomGamesSheet> createState() => _RoomGamesSheetState();
}

class _RoomGamesSheetState extends State<RoomGamesSheet> {
  late final RoomGamesService _service;
  final _answer = TextEditingController();
  Timer? _poll, _tick;
  Map<String, dynamic>? _data;
  String _mode = 'vocabulary', _level = 'beginner', _language = 'en';
  String? _error, _notice, _visibleSession;
  int? _index;
  bool _fetching = false, _busy = false;
  DateTime _receivedAt = DateTime.now();
  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? RoomGamesService(roomId: widget.roomId);
    unawaited(_load());
    _poll = Timer.periodic(const Duration(seconds: 5),
      (_) => unawaited(_load(silent: true)));
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _data?['active'] == true) setState(() {});
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    _answer.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (_busy || _fetching) return;
    _fetching = true;
    try {
      final data = await _service.status();
      if (!mounted) return;
      final session = data['sessionId']?.toString();
      final index = (data['questionIndex'] as num?)?.toInt();
      final langs = (data['languages'] as List?)?.cast<String>() ??
        const <String>[];
      setState(() {
        _data = data;
        _error = null;
        _receivedAt = DateTime.now();
        if (langs.isNotEmpty && !langs.contains(_language)) {
          _language = langs.first;
        }
        if (_visibleSession != session || _index != index) {
          _visibleSession = session;
          _index = index;
          _answer.clear();
          _notice = null;
        }
      });
    } catch (error) {
      if (mounted && (!silent || _data == null)) {
        setState(() => _error =
            error.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      _fetching = false;
    }
  }

  Future<void> _start() async {
    if (!widget.isHost || _busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      await _service.start(mode: _mode, level: _level, language: _language);
      // Game questions are shown inside the room, not in this large modal.
      // Return to the eight seats immediately after starting successfully.
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() =>
            _error = error.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      await _load();
    }
  }

  Future<void> _send() async {
    final data = _data;
    if (_busy || data?['canAnswer'] != true || data?['answered'] == true ||
        data?['active'] != true || _answer.text.trim().isEmpty) {
      return;
    }
    final id = data?['sessionId']?.toString();
    final idx = (data?['questionIndex'] as num?)?.toInt();
    if (id == null || idx == null) return;
    setState(() { _busy = true; _error = null; });
    try {
      final result = await _service.answer(
        sessionId: id, wordIndex: idx, answer: _answer.text.trim());
      if (mounted) {
        setState(() {
        _notice = result['alreadySubmitted'] == true
          ? (_ar ? 'تم إرسال الإجابة من قبل' : 'Already submitted')
          : result['correct'] == true
              ? (_ar ? 'صحيح! +10 نقاط لعب' : 'Correct! +10 game points')
              : (_ar ? 'حاول في الكلمة القادمة' : 'Try the next word');
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() =>
            _error = error.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      await _load();
    }
  }

  int get _remaining {
    final initial = (_data?['secondsLeft'] as num?)?.toInt() ?? 0;
    return math.max(0,
      initial - DateTime.now().difference(_receivedAt).inSeconds);
  }

  String _gameTitle(String mode) => mode == 'guess'
    ? (_ar ? 'خمّن الكلمة' : 'Guess the Word')
    : (_ar ? 'المفردات' : 'Vocabulary');

  Widget _setup() {
    final langs = (_data?['languages'] as List?)?.cast<String>() ??
        const <String>[];
    final quota = ((_data?['remaining'] as Map?)?[_mode] as num?)?.toInt() ?? 0;
    return Card(
      color: const Color(0xFF164C39),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_ar ? 'صاحب الروم يختار اللعبة والمستوى'
                : 'Host chooses the game and level',
              style: const TextStyle(fontSize: 17,
                color: Color(0xFFF1D28B), fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'vocabulary',
                    label: Text(_gameTitle('vocabulary'))),
                ButtonSegment(value: 'guess',
                    label: Text(_gameTitle('guess'))),
              ],
              selected: {_mode},
              onSelectionChanged: (values) =>
                  setState(() => _mode = values.first),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _level,
              decoration: InputDecoration(
                labelText: _ar ? 'المستوى' : 'Difficulty'),
              items: const [
                DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                DropdownMenuItem(value: 'intermediate',
                    child: Text('Intermediate')),
                DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _level = v);
              },
            ),
            const SizedBox(height: 12),
            if (langs.isEmpty)
              Text(_ar
                  ? 'بنك الكلمات الحالي: عربي وإنجليزي وفرنسي. لغات إضافية قادمة.'
                  : 'Word banks currently support Arabic, English and French.',
                style: const TextStyle(color: Color(0xFFFFD7A0)))
            else
              Wrap(spacing: 7, children: [
                for (final lang in langs)
                  ChoiceChip(label: Text(lang.toUpperCase()),
                    selected: _language == lang,
                    onSelected: (_) => setState(() => _language = lang)),
              ]),
            const SizedBox(height: 12),
            Text(_ar
              ? '5 كلمات، 30 ثانية لكل كلمة · المتبقي اليوم: $quota من 5'
              : '5 words, 30 seconds per word · $quota of 5 free starts left',
              style: const TextStyle(color: Color(0xFFD3E2D6), fontSize: 12)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy || quota < 1 || langs.isEmpty ? null : _start,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(_ar ? 'بدء الجولة' : 'Start session'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE3C476),
                foregroundColor: const Color(0xFF153B2E)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameView() {
    final data = _data!;
    final active = data['active'] == true;
    final finished = data['finished'] == true;
    if (!active && !finished) {
      return Padding(
        padding: const EdgeInsets.all(25),
        child: Center(child: Text(_ar ? 'انتظر المضيف ليبدأ الجولة'
          : 'Waiting for the host to start a round')));
    }
    final mode = data['mode']?.toString() ?? 'vocabulary';
    final idx = (data['questionIndex'] as num?)?.toInt() ?? 0;
    final question = data['question'] as Map?;
    final points = (data['leaderboard'] as List?) ?? const [];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 15),
      Row(children: [
        Expanded(child: Text(_gameTitle(mode),
          style: const TextStyle(color: Color(0xFFF1D28B),
            fontWeight: FontWeight.w900, fontSize: 19))),
        Text((data['language'] ?? '').toString().toUpperCase(),
          style: const TextStyle(color: Color(0xFFCCDECB))),
      ]),
      const SizedBox(height: 10),
      if (active) ...[
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${_ar ? 'الكلمة ' : 'Word '}${idx + 1}/5'),
          Text('${_remaining}s',
            style: const TextStyle(color: Color(0xFFE5C782),
              fontWeight: FontWeight.w900, fontSize: 18)),
        ]),
        const SizedBox(height: 7),
        LinearProgressIndicator(value: _remaining / 30,
          backgroundColor: const Color(0xFF235740),
          color: const Color(0xFFE5C782), minHeight: 6),
        const SizedBox(height: 15),
        Container(padding: const EdgeInsets.all(21),
          decoration: BoxDecoration(
            color: const Color(0xFF164B39),
            borderRadius: BorderRadius.circular(18)),
          child: Column(children: [
            Text(mode == 'guess'
                ? (_ar ? 'رتب هذه الحروف' : 'Unscramble these letters')
                : (_ar ? 'اكتب الكلمة المناسبة للتعريف'
                    : 'Type the word matching the definition'),
              style: const TextStyle(color: Color(0xFFDBE8DB))),
            const SizedBox(height: 13),
            Text(question?['clue']?.toString() ?? '',
              textAlign: TextAlign.center,
              textDirection: data['language'] == 'ar'
                ? TextDirection.rtl : TextDirection.ltr,
              style: TextStyle(fontSize: mode == 'guess' ? 25 : 19,
                fontWeight: FontWeight.w900,
                letterSpacing: mode == 'guess' ? 2 : 0)),
          ])),
        const SizedBox(height: 12),
        if (data['canAnswer'] != true)
          Text(_ar
              ? 'خمّن الكلمة للموجودين على المسرح فقط؛ المستمع يشاهد.'
              : 'Guess the Word is stage-only. Listeners can watch.',
            style: const TextStyle(color: Color(0xFFFFD9A3)),
            textAlign: TextAlign.center)
        else if (data['answered'] == true)
          Text(_ar ? 'تم تسجيل إجابتك، انتظر الكلمة التالية.'
              : 'Answer recorded. Wait for the next word.',
            textAlign: TextAlign.center)
        else ...[
          TextField(controller: _answer, maxLength: 80,
            enabled: !_busy && _remaining > 0,
            textDirection: data['language'] == 'ar'
              ? TextDirection.rtl : TextDirection.ltr,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              labelText: _ar ? 'إجابتك' : 'Your answer',
              border: const OutlineInputBorder())),
          FilledButton.icon(onPressed: _busy || _remaining == 0 ? null : _send,
            icon: const Icon(Icons.check_rounded),
            label: Text(_ar ? 'إرسال' : 'Submit')),
        ],
        if (_notice != null)
          Padding(padding: const EdgeInsets.only(top: 8),
            child: Text(_notice!, textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFFDD91)))),
      ] else if (finished) ...[
        Text(_ar ? 'انتهت الجولة' : 'Session finished',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        if (data['solutions'] is List)
          Text((_ar ? 'الكلمات: ' : 'Words: ') +
            (data['solutions'] as List).join(' · ')),
      ],
      const SizedBox(height: 19),
      Text(_ar ? 'الترتيب · نقاط اللعب' : 'Leaderboard · Game points',
        style: const TextStyle(color: Color(0xFFE4C477),
          fontWeight: FontWeight.w900)),
      if (points.isEmpty)
        Text(_ar ? 'لا توجد إجابات بعد' : 'No answers yet')
      else
        for (var i = 0; i < points.length; i++)
          ListTile(dense: true,
            leading: Text(i < 3 ? ['🥇', '🥈', '🥉'][i] : (i + 1).toString()),
            title: Text((points[i] as Map)['name']?.toString() ?? 'WorldVoice'),
            trailing: Text(((points[i] as Map)['points'] ?? 0).toString(),
              style: const TextStyle(color: Color(0xFFE7CB80),
                fontWeight: FontWeight.w900))),
    ]);
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: SizedBox(
    height: MediaQuery.sizeOf(context).height * .84,
    child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 6, 8),
        child: Row(children: [
          const Icon(Icons.sports_esports_rounded, color: Color(0xFFE4CA80)),
          const SizedBox(width: 9),
          Expanded(child: Text('WorldVoice Games',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900))),
          IconButton(onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh_rounded)),
          IconButton(onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded)),
        ])),
      Expanded(child: ListView(
        padding: EdgeInsets.fromLTRB(16, 6, 16,
          MediaQuery.viewInsetsOf(context).bottom + 20),
        children: [
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          if (_data == null && _error == null)
            const Center(child: CircularProgressIndicator()),
          if (_data != null) ...[
            if (widget.isHost && _data?['active'] != true) _setup(),
            _gameView(),
          ],
          if (!widget.isHost)
            Padding(padding: const EdgeInsets.only(top: 12),
              child: Text(_ar
                ? 'المفردات للجميع بما فيهم المستمعون. تخمين الحروف للمسرح فقط.'
                : 'Vocabulary is open to listeners. Letter guessing is stage-only.',
                style: const TextStyle(color: Color(0xFFBED7C8)))),
        ],
      )),
    ]),
  ));
}
