import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:worldvoice/features/rooms/data/classic_gift_catalog.dart';
import 'package:worldvoice/features/rooms/data/room_feature_models.dart';
import 'package:worldvoice/features/rooms/presentation/room_gift_overlay.dart';
import 'package:worldvoice/features/rooms/presentation/classic_gift_visual.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first-tier gift is borderless and animates for preview',
      (tester) async {
    final designs = await ClassicGiftCatalog.load();
    final butterfly = designs.firstWhere(
        (gift) => gift.id == 'classic_luminous_butterfly');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: ClassicGiftVisual(gift: butterfly, animate: true),
        ),
      ),
    ));
    expect(find.byType(Card), findsNothing);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.takeException(), isNull);
  });
  testWidgets('in-room preview is labeled and does not show a gift receipt',
      (tester) async {
    // Explicitly load bundled artwork metadata before verifying its caption.
    const preview = RoomGiftCatalogItem(
      id: 'classic_golden_phoenix', name: 'Golden Phoenix',
      nameAr: 'العنقاء الذهبية', priceCoins: 50,
      active: false, emoji: '🐦‍🔥', effectType: 'phoenix',
    );
    const sample = RoomGiftEvent(
      id: 'demo',
      senderId: 'preview',
      senderName: 'Preview',
      recipientId: '',
      recipientName: '',
      giftId: 'classic_golden_phoenix',
      points: 50,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RoomGiftOverlay(
          event: sample, preview: true, previewGift: preview),
      ),
    ));
    await tester.pump();
    expect(find.textContaining('PREVIEW'), findsOneWidget);
    expect(find.byType(ClassicGiftVisual), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 120));
    // Artwork metadata is loaded asynchronously; the no-charge watermark
    // must render immediately even if image/catalog loading is delayed.
    expect(find.textContaining('Gift sent'), findsNothing);
    expect(tester.takeException(), isNull);
  });

}
