import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worldvoice/features/profile/presentation/world_bond_screen.dart';

void main() {
  testWidgets('failed send never reports success and retry keeps idempotency key', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final keys = <String?>[];
    Future<Map<String,dynamic>> request(String path,
        {Map<String,dynamic>? body, String? idempotencyKey}) async {
      if(path.startsWith('world-bond/overview')) {
        return {'ok':true,'bonds':[{'type':'friend','status':'active','level':1,
          'xp':0,'members':['alice','bob']}], 'specialGifts':[
          {'id':'wv_bond_01','name':'Emerald Promise','nameAr':'وعد الزمرد',
            'level':1,'priceCoins':100}]};
      }
      expect(path,'world-bond/gifts/send');
      expect(body?['type'],'friend');
      keys.add(idempotencyKey);
      throw StateError('NOT_ENOUGH_COINS');
    }
    await tester.pumpWidget(MaterialApp(home: WorldBondScreen(
      peerId:'bob',peerName:'Bob',viewerId:'alice',request:request)));
    await tester.pumpAndSettle();
    for(var i=0;i<2;i++) {
      final button = find.widgetWithText(FilledButton,'Send');
      await tester.scrollUntilVisible(button, 250);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.textContaining('100 coins'),findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton,'Send').last);
      await tester.pumpAndSettle();
      expect(find.text('Gift delivered'),findsNothing);
    }
    expect(keys.length,2);
    expect(keys[0],keys[1]);
    expect(tester.takeException(),isNull);
  });
}
