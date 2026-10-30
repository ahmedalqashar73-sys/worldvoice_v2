import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/live/presentation/live_camera_off_tile.dart';

void main() {
  for (final (size, languageCode) in <(Size, String)>[
    (const Size(360, 480), 'ar'),
    (const Size(180, 160), 'en'),
    (const Size(92, 88), 'ar'),
    (const Size(75, 65), 'en'),
  ]) {
    testWidgets(
      'camera-off state fits ${size.width}x${size.height} in $languageCode',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: LiveCameraOffTile(ar: languageCode == 'ar'),
                ),
              ),
            ),
          ),
        );

        expect(find.byKey(const ValueKey('live-camera-off-state')), findsOneWidget);
        expect(find.byIcon(Icons.videocam_off_rounded), findsOneWidget);
        expect(
          find.text(languageCode == 'ar' ? 'الكاميرا مغلقة' : 'Camera off'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('invalid guest photo keeps an emerald placeholder', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            height: 180,
            child: LiveCameraOffTile(
              ar: true,
              photoUrl: 'not-a-network-image',
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(find.byIcon(Icons.videocam_off_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
