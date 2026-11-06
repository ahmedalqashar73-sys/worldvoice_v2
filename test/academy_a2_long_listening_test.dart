import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/presentation/a2_long_listening_section.dart';
import 'package:worldvoice/features/learn/presentation/voa_originals_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('A2 long listening has six sessions, 5 unique real VOA recordings each',
      () async {
    final originals = await const VoaOriginalCatalog(level: 'A2').load();
    final sessions = buildA2LongSessions(originals);
    expect(sessions, hasLength(6));
    expect(sessions.every((s) => s.lessons.length == 5), isTrue);
    expect(sessions.expand((s) => s.lessons).map((e) => e.number).toList(),
        List<int>.generate(30, (i) => i + 1));
    expect(sessions.expand((s) => s.lessons).map((e) => e.id).toSet(),
        hasLength(30));
    for (final session in sessions) {
      expect(session.durationSec, greaterThanOrEqualTo(20 * 60));
      expect(session.durationSec, lessThan(26 * 60));
      expect(session.lessons.every((e) => e.isOfficialSource), isTrue);
      expect(session.durationSec,
          session.lessons.fold<int>(0, (total, e) => total + e.durationSec));
    }
  });

  test('fail closed on missing, duplicate or out-of-order A2 audio', () async {
    final originals = await const VoaOriginalCatalog(level: 'A2').load();
    expect(() => buildA2LongSessions(originals.take(29).toList()),
        throwsFormatException);
    final duplicated = [...originals];
    duplicated[29] = originals.first;
    expect(() => buildA2LongSessions(duplicated), throwsFormatException);
  });

  testWidgets('six A2 long sessions and official VOA podcast link',
      (tester) async {
    final originals = await tester.runAsync(
        () => const VoaOriginalCatalog(level: 'A2').load());
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: A2LongListeningSection(initialLessons: originals!),
      )),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey('a2-long-session-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('a2-long-session-6')), findsOneWidget);
    expect(find.byKey(const ValueKey('a2-long-official-voa')), findsOneWidget);
    expect(find.textContaining('Lessons 1–5'), findsOneWidget);
  });
}
