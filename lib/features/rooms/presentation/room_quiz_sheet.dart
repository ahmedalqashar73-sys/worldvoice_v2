import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/room_feature_models.dart';
import '../services/room_feature_service.dart';

class RoomQuizSheet extends StatefulWidget {
  const RoomQuizSheet({
    required this.roomId,
    required this.isHost,
    super.key,
  });

  final String roomId;
  final bool isHost;

  @override
  State<RoomQuizSheet> createState() => _RoomQuizSheetState();
}

class _RoomQuizSheetState extends State<RoomQuizSheet> {
  late final RoomFeatureService _service;

  @override
  void initState() {
    super.initState();
    _service = RoomFeatureService(roomId: widget.roomId);
  }

  Future<void> _createQuiz() async {
    final question = TextEditingController();
    final a = TextEditingController();
    final b = TextEditingController();
    final c = TextEditingController();
    final d = TextEditingController();
    var correctIndex = 0;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Create quiz'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: question,
                  decoration: const InputDecoration(labelText: 'Question'),
                ),
                TextField(
                  controller: a,
                  decoration: const InputDecoration(labelText: 'Option A'),
                ),
                TextField(
                  controller: b,
                  decoration: const InputDecoration(labelText: 'Option B'),
                ),
                TextField(
                  controller: c,
                  decoration: const InputDecoration(labelText: 'Option C'),
                ),
                TextField(
                  controller: d,
                  decoration: const InputDecoration(labelText: 'Option D'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: correctIndex,
                  decoration:
                      const InputDecoration(labelText: 'Correct answer'),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('A')),
                    DropdownMenuItem(value: 1, child: Text('B')),
                    DropdownMenuItem(value: 2, child: Text('C')),
                    DropdownMenuItem(value: 3, child: Text('D')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setLocalState(() => correctIndex = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final options = [a.text.trim(), b.text.trim(), c.text.trim(), d.text.trim()]
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      if (question.text.trim().isNotEmpty && options.length >= 2) {
        final safeCorrect = correctIndex.clamp(0, options.length - 1);
        await _service.startQuiz(
          question: question.text.trim(),
          options: options,
          correctIndex: safeCorrect,
        );
      }
    }

    question.dispose();
    a.dispose();
    b.dispose();
    c.dispose();
    d.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: StreamBuilder<RoomFeatureState>(
          stream: _service.watchState(),
          builder: (context, stateSnapshot) {
            final state = stateSnapshot.data;
            final hasQuiz = state?.quizQuestion?.isNotEmpty == true;

            if (!hasQuiz) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.quiz_rounded, size: 54),
                      const SizedBox(height: 12),
                      Text(
                        isArabic
                            ? 'لا يوجد كويز نشط الآن'
                            : 'No active quiz right now',
                      ),
                      if (widget.isHost) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _createQuiz,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(
                            isArabic ? 'إنشاء سؤال' : 'Create question',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _service.watchQuizAnswers(),
              builder: (context, answerSnapshot) {
                final answers = answerSnapshot.data?.docs ??
                    const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                QueryDocumentSnapshot<Map<String, dynamic>>? myAnswer;
                for (final answer in answers) {
                  if (answer.id == uid) {
                    myAnswer = answer;
                    break;
                  }
                }

                final counts =
                    List<int>.filled(state!.quizOptions.length, 0);
                for (final answer in answers) {
                  final index =
                      (answer.data()['optionIndex'] as num?)?.toInt();
                  if (index != null &&
                      index >= 0 &&
                      index < counts.length) {
                    counts[index]++;
                  }
                }

                return ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            state.quizQuestion!,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (widget.isHost)
                          IconButton(
                            onPressed: _createQuiz,
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    for (var i = 0; i < state.quizOptions.length; i++)
                      Card(
                        color: state.quizRevealed &&
                                i == state.quizCorrectIndex
                            ? Colors.green.withValues(alpha: .22)
                            : null,
                        child: ListTile(
                          title: Text(state.quizOptions[i]),
                          subtitle: state.quizRevealed
                              ? Text('${counts[i]} vote(s)')
                              : null,
                          trailing:
                              (myAnswer?.data()['optionIndex'] as num?)
                                          ?.toInt() ==
                                      i
                                  ? const Icon(Icons.check_circle_rounded)
                                  : null,
                          onTap: state.quizRevealed || myAnswer != null
                              ? null
                              : () => _service.answerQuiz(i),
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (widget.isHost && !state.quizRevealed)
                      FilledButton.icon(
                        onPressed: _service.finishQuiz,
                        icon: const Icon(Icons.visibility_rounded),
                        label: Text(
                          isArabic ? 'إظهار النتيجة' : 'Reveal result',
                        ),
                      ),
                    if (state.quizRevealed &&
                        state.quizWinners.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        isArabic ? 'الفائزون' : 'Winners',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      for (final winner in state.quizWinners)
                        Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                switch ((winner['place'] as num?)?.toInt()) {
                                  1 => '🥇',
                                  2 => '🥈',
                                  3 => '🥉',
                                  _ => '🏅',
                                },
                              ),
                            ),
                            title: Text(
                              (winner['displayName'] ??
                                      'WorldVoice user')
                                  .toString(),
                            ),
                            subtitle: Text(
                              isArabic
                                  ? 'المركز ${winner['place']}'
                                  : 'Place ${winner['place']}',
                            ),
                            trailing:
                                (winner['prizeCoins'] as num?)?.toInt() == 5
                                    ? const Text(
                                        '+5 🪙',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      )
                                    : null,
                          ),
                        ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
