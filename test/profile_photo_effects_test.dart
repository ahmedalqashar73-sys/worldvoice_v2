import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/profile/presentation/profile_photo_viewer.dart';

void main() {
  test('avatar effects have a neutral original and distinct visual presets', () {
    final original = avatarPhotoFilter(0);
    final mono = avatarPhotoFilter(1);
    final warm = avatarPhotoFilter(2);

    expect(original, isA<ColorFilter>());
    expect(mono, isA<ColorFilter>());
    expect(warm, isA<ColorFilter>());
    expect(mono, isNot(equals(warm)));
    expect(original, isNot(equals(mono)));
  });

  testWidgets('previewing effects never commits; Save requires changed selection',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('en'),
      home: ProfileAvatarEffectsScreen(
        userId: 'test-user',
        photoUrl: 'https://example.invalid/profile.jpg',
      ),
    ));
    await tester.pump();

    expect(find.byKey(const ValueKey('avatar-effect-preview')), findsOneWidget);
    expect(find.byKey(const ValueKey('avatar-filter-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('avatar-filter-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('avatar-filter-2')), findsOneWidget);

    FilledButton save = tester.widget<FilledButton>(
      find.byKey(const ValueKey('avatar-filter-save')),
    );
    expect(save.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('avatar-filter-1')));
    await tester.pump();

    save = tester.widget<FilledButton>(
      find.byKey(const ValueKey('avatar-filter-save')),
    );
    expect(save.onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('avatar-filter-0')));
    await tester.pump();
    save = tester.widget<FilledButton>(
      find.byKey(const ValueKey('avatar-filter-save')),
    );
    expect(save.onPressed, isNull);
  });
}
