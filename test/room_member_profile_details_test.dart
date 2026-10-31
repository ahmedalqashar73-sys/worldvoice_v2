import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/presentation/room_member_profile_details.dart';

void main() {
  testWidgets('profile shows all languages, recorded proficiency and server badge', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: RoomMemberProfileDetails(
      userId: 'host', isArabic: false,
      badgeLoader: (_) async => {'giftLevel': 7},
      profile: const {'nativeLanguageCode': 'ar',
        'learningLanguageCodes': ['en','es','fr'],
        'learningLanguageLevels': {'en':'B2','es':'A1','fr':'C1'}},
    ))));
    await tester.pumpAndSettle();
    expect(find.textContaining('B2'), findsOneWidget);
    expect(find.textContaining('A1'), findsOneWidget);
    expect(find.textContaining('C1'), findsOneWidget);
    expect(find.text('Gift level'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
