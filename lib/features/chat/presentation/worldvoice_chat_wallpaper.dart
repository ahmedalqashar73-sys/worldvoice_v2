import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vector wallpapers: high-resolution on every screen without large images.
class WorldVoiceChatWallpaper extends StatelessWidget {
  const WorldVoiceChatWallpaper({
    required this.index, required this.child, super.key,
  });
  final int index;
  final Widget child;

  static const names = <String>[
    'Emerald Calm', 'Warm Cream', 'Blue Mist',
    'Soft Lavender', 'Cloud Gray', 'Olive Peace',
  ];

  static const palettes = <List<Color>>[
    [Color(0xFFE3EEE9), Color(0xFFC8E0D5), Color(0xFFECF5EF)],
    [Color(0xFFFFF8EB), Color(0xFFF5EBDD), Color(0xFFFFFCF7)],
    [Color(0xFFEAF2F5), Color(0xFFD6E7EC), Color(0xFFF2F7F8)],
    [Color(0xFFF3EDF8), Color(0xFFE5DBF0), Color(0xFFFAF6FC)],
    [Color(0xFFF0F3F5), Color(0xFFDCE4E9), Color(0xFFF8FAFB)],
    [Color(0xFFEEF0DF), Color(0xFFDEE5C9), Color(0xFFF7F7EA)],
  ];

  static String _key(String uid, String chatId) => 'wv_wallpaper_${uid}_$chatId';

  static Future<int> load(String uid, String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_key(uid, chatId)) ?? 0).clamp(0, 5);
  }

  static Future<void> save(String uid, String chatId, int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(uid, chatId), index.clamp(0, 5));
  }

  @override
  Widget build(BuildContext context) {
    final colors = palettes[index.clamp(0, palettes.length - 1)];
    return Stack(fit: StackFit.expand, children: [
      DecoratedBox(decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: colors,
        ),
      )),
      IgnorePointer(child: CustomPaint(
        painter: _WallpaperWatermarkPainter(),
      )),
      child,
    ]);
  }
}

class _WallpaperWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wash = Paint()
      ..color = const Color(0xFF507E6C).withValues(alpha: .055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..moveTo(-40, size.height * .28)
      ..cubicTo(size.width * .25, size.height * .15,
        size.width * .70, size.height * .42,
        size.width + 45, size.height * .26)
      ..moveTo(-40, size.height * .78)
      ..cubicTo(size.width * .35, size.height * .57,
        size.width * .61, size.height * .99,
        size.width + 45, size.height * .76);
    canvas.drawPath(path, wash);
    final label = TextPainter(
      text: TextSpan(text: 'WorldVoice',
        style: TextStyle(color: const Color(0xFF35564C).withValues(alpha: .10),
          fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset((size.width - label.width) / 2,
        (size.height - label.height) / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<void> showWorldVoiceWallpaperPicker(
  BuildContext context, {
  required int selected,
  required ValueChanged<int> onSelected,
}) async {
  await showModalBottomSheet<void>(
    context: context, useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('WorldVoice • Chat Wallpapers',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: WorldVoiceChatWallpaper.names.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 12,
            mainAxisSpacing: 12, childAspectRatio: .78,
          ),
          itemBuilder: (_, index) => InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              onSelected(index);
              Navigator.pop(sheetContext);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(fit: StackFit.expand, children: [
                WorldVoiceChatWallpaper(index: index,
                  child: const SizedBox.expand()),
                if (index == selected)
                  const Align(alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.check_circle, color: Color(0xFF127E55)),
                    )),
                Align(alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity, color: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(WorldVoiceChatWallpaper.names[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF285044),
                        fontSize: 10, fontWeight: FontWeight.w700)),
                  )),
              ]),
            ),
          ),
        ),
      ]),
    ),
  );
}
