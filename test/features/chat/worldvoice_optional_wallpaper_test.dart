import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worldvoice/core/theme/worldvoice_appearance.dart';
import 'package:worldvoice/features/chat/presentation/worldvoice_chat_wallpaper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('direct chat starts without a forced background', () async {
    final selected = await WorldVoiceChatWallpaper.load('userA', 'chatA');
    expect(selected, WorldVoiceChatWallpaper.none);
    expect(WorldVoiceChatWallpaper.paths.length, 6);
  });

  test('each chat stores its own opt-in wallpaper', () async {
    await WorldVoiceChatWallpaper.save('userA', 'chatA', 3);
    expect(await WorldVoiceChatWallpaper.load('userA', 'chatA'), 3);
    expect(await WorldVoiceChatWallpaper.load('userA', 'chatB'),
        WorldVoiceChatWallpaper.none);
    await WorldVoiceChatWallpaper.save('userA', 'chatA',
        WorldVoiceChatWallpaper.none);
    expect(await WorldVoiceChatWallpaper.load('userA', 'chatA'),
        WorldVoiceChatWallpaper.none);
  });

  test('WorldVoice global appearance starts dark and can be changed', () async {
    final appearance = WorldVoiceAppearance.instance;
    await appearance.load();
    expect(appearance.mode.value, ThemeMode.dark);
    await appearance.setMode(ThemeMode.light);
    expect(appearance.mode.value, ThemeMode.light);
    await appearance.load();
    expect(appearance.mode.value, ThemeMode.light);
  });

  testWidgets('no-wallpaper screen is a solid theme background', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: const WorldVoiceChatWallpaper(
        index: WorldVoiceChatWallpaper.none,
        child: Center(child: Text('WorldVoice private chat')),
      ),
    ));
    expect(find.text('WorldVoice private chat'), findsOneWidget);
    expect(find.byType(ColoredBox), findsWidgets);
  });
}
