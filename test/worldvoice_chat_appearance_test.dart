import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worldvoice/core/theme/worldvoice_appearance.dart';
import 'package:worldvoice/features/chat/presentation/worldvoice_chat_wallpaper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    WorldVoiceAppearance.instance.mode.value = ThemeMode.dark;
  });

  test('WorldVoice starts in dark mode and saves appearance choices', () async {
    final appearance = WorldVoiceAppearance.instance;
    await appearance.load();
    expect(appearance.mode.value, ThemeMode.dark);

    await appearance.setMode(ThemeMode.light);
    await appearance.load();
    expect(appearance.mode.value, ThemeMode.light);

    await appearance.setMode(ThemeMode.system);
    await appearance.load();
    expect(appearance.mode.value, ThemeMode.system);
  });

  test('Chat wallpapers default to none and are stored per conversation', () async {
    expect(await WorldVoiceChatWallpaper.load('user', 'chat1'),
        WorldVoiceChatWallpaper.none);
    await WorldVoiceChatWallpaper.save('user', 'chat1', 4);
    expect(await WorldVoiceChatWallpaper.load('user', 'chat1'), 4);
    expect(await WorldVoiceChatWallpaper.load('user', 'chat2'),
        WorldVoiceChatWallpaper.none);

    await WorldVoiceChatWallpaper.save(
        'user', 'chat1', WorldVoiceChatWallpaper.none);
    expect(await WorldVoiceChatWallpaper.load('user', 'chat1'),
        WorldVoiceChatWallpaper.none);
  });

  test('The six premium WorldVoice SVG backgrounds are bundled', () async {
    expect(WorldVoiceChatWallpaper.paths.length, 6);
    expect(WorldVoiceChatWallpaper.names.length, 6);
    expect(WorldVoiceChatWallpaper.localizedNames.length, 6);
    for (final path in WorldVoiceChatWallpaper.paths) {
      final svg = await rootBundle.loadString(path);
      expect(svg, contains('<svg'));
      expect(svg, contains('</svg>'));
    }
  });

  testWidgets('Without a wallpaper, the dark screen remains clean',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(
          body: WorldVoiceChatWallpaper(
            index: WorldVoiceChatWallpaper.none,
            child: Center(child: Text('WorldVoice Chat')),
          ),
        ),
      ),
    );
    expect(find.text('WorldVoice Chat'), findsOneWidget);
    expect(find.text('WorldVoice'), findsNothing);
    final background = tester.widget<ColoredBox>(find.byWidgetPredicate(
      (widget) => widget is ColoredBox &&
          widget.color == const Color(0xFF0F1115),
    ));
    expect(background.color, const Color(0xFF0F1115));
  });
}
