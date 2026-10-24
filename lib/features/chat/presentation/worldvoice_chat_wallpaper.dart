import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User wallpapers are purely cosmetic and saved only on this device.
/// -1 means no wallpaper; use the selected WorldVoice app appearance.
class WorldVoiceChatWallpaper extends StatelessWidget {
  const WorldVoiceChatWallpaper({
    required this.index, required this.child, super.key,
  });

  final int index;
  final Widget child;

  static const int none = -1;
  static const names = <String>[
    'Midnight', 'Emerald', 'Pearl White',
    'Sakura', 'Galaxy', 'Rose',
  ];
  static const localizedNames = <String>[
    'منتصف الليل', 'الزمرد', 'اللؤلؤ الأبيض',
    'ساكورا', 'المجرة', 'الورد',
  ];
  static const paths = <String>[
    'assets/chat_wallpapers/midnight.svg',
    'assets/chat_wallpapers/emerald.svg',
    'assets/chat_wallpapers/pearl_white.svg',
    'assets/chat_wallpapers/sakura.svg',
    'assets/chat_wallpapers/galaxy.svg',
    'assets/chat_wallpapers/rose.svg',
  ];

  // New key intentionally discards the old *forced* pale wallpaper default.
  static String _key(String uid, String chatId) =>
      'worldvoice_optional_wallpaper_v2_${uid}_$chatId';

  static Future<int> load(String uid, String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_key(uid, chatId)) ?? none).clamp(none, paths.length - 1);
  }

  static Future<void> save(String uid, String chatId, int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _key(uid, chatId), index.clamp(none, paths.length - 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (index == none || index < none || index >= paths.length) {
      return ColoredBox(
        color: dark ? const Color(0xFF0F1115) : const Color(0xFFF4F6F5),
        child: child,
      );
    }

    return Stack(fit: StackFit.expand, children: [
      SvgPicture.asset(
        paths[index],
        fit: BoxFit.cover,
        placeholderBuilder: (_) => const ColoredBox(color: Color(0xFF101A1B)),
      ),
      // Decorative paintings never reduce legibility of chat bubbles.
      const ColoredBox(color: Color(0x3D080B12)),
      IgnorePointer(
        child: Align(
          alignment: const Alignment(0, .04),
          child: Text(
            'WorldVoice',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .13),
              fontSize: 29,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
      child,
    ]);
  }
}

Future<void> showWorldVoiceWallpaperPicker(
  BuildContext context, {
  required int selected,
  required ValueChanged<int> onSelected,
}) async {
  final ar = Localizations.localeOf(context).languageCode == 'ar';
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFF171B20),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 5, 18, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            ar ? 'خلفية محادثة WorldVoice' : 'WorldVoice chat background',
            style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            ar ? 'اختيارية لكل محادثة • مريحة للعين'
               : 'Optional for each conversation • Easy on the eyes',
            style: const TextStyle(color: Color(0xFFABB6B2), fontSize: 12),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: paths.length + 1,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, childAspectRatio: .65,
                crossAxisSpacing: 12, mainAxisSpacing: 14,
              ),
              itemBuilder: (itemContext, tileIndex) {
                final value = tileIndex - 1;
                final active = value == selected;
                return InkWell(
                  key: ValueKey('worldvoice-wallpaper-$value'),
                  onTap: () {
                    onSelected(value);
                    Navigator.pop(sheetContext);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Column(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(fit: StackFit.expand, children: [
                          if (value == none)
                            const ColoredBox(color: Color(0xFF0F1115))
                          else
                            SvgPicture.asset(paths[value], fit: BoxFit.cover),
                          if (value != none)
                            const ColoredBox(color: Color(0x29040D17)),
                          Center(
                            child: Text(
                              'WorldVoice',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .32),
                                fontSize: 10, fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (active)
                            const PositionedDirectional(
                              top: 6, end: 6,
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF72E1B7),
                              ),
                            ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      value == none
                        ? (ar ? 'بدون خلفية' : 'No background')
                        : (ar ? localizedNames[value] : names[value]),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active ? const Color(0xFF7AE2B4) : Colors.white,
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    ),
  );
}
