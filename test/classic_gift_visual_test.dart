import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldvoice/features/rooms/data/classic_gift_catalog.dart';
import 'package:worldvoice/features/rooms/data/room_feature_models.dart';
import 'package:worldvoice/features/rooms/presentation/room_gift_overlay.dart';
import 'package:worldvoice/features/rooms/presentation/classic_gift_visual.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('WorldVoice gift is borderless and supports send-only animation',
      (tester) async {
    final designs = await ClassicGiftCatalog.load();
    final butterfly = designs.firstWhere(
      (gift) => gift.id == 'wv_gift_010',
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: ClassicGiftVisual(gift: butterfly, animate: true),
        ),
      ),
    ));

    expect(find.byType(Card), findsNothing);
    expect(find.byType(ClassicGiftVisual), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.takeException(), isNull);
  });

  testWidgets('in-room preview is labeled and never looks like a paid receipt',
      (tester) async {
    const preview = RoomGiftCatalogItem(
      id: 'wv_gift_012',
      name: 'Flame Phoenix',
      nameAr: 'عنقاء اللهب',
      priceCoins: 45,
      active: false,
      emoji: '🐦‍🔥',
      effectType: 'phoenix',
    );
    const sample = RoomGiftEvent(
      id: 'demo',
      senderId: 'preview',
      senderName: 'Preview',
      recipientId: '',
      recipientName: '',
      giftId: 'wv_gift_012',
      points: 45,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RoomGiftOverlay(
          event: sample,
          preview: true,
          previewGift: preview,
        ),
      ),
    ));

    await tester.pump();
    expect(find.text('PREVIEW • NO COINS CHARGED'), findsOneWidget);
    expect(find.byType(ClassicGiftVisual), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.textContaining('Gift sent'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
