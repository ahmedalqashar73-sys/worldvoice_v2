import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/learn/presentation/voa_originals_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('15 real VOA originals, one source and Anna as recurring voice',
      () async {
    final list = await const VoaOriginalCatalog().load();
    expect(list, hasLength(15));
    expect(list.map((e) => e.id).toSet(), hasLength(15));
    expect(list.every((e) => e.isOfficialSource), isTrue);
    expect(list.where((e) => e.petePresent), hasLength(8));
    expect(list.where((e) => e.existingEpisodeId != null), hasLength(3));
    expect(list.where((e) => e.existingEpisodeId == null), hasLength(12));
  });

  testWidgets('VOA originals section presents native audio list',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: VoaOriginalsSection(onOpen: (_) {}))),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const ValueKey('podcast-original-en-a1-voa-001')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('podcast-original-en-a1-voa-020')),
        findsOneWidget);
    expect(find.text('VOA human audio · provisional sync'), findsOneWidget);
  });
}
