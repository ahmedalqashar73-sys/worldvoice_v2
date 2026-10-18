import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lightweight hand-authored vector illustrations: no network images, no
/// copyrighted characters, and gentle motion that can run offline.
class AcademyIllustratedStoryArt extends StatefulWidget {
  const AcademyIllustratedStoryArt({
    required this.scene, required this.page, super.key,
  });
  final int scene;
  final int page;

  @override
  State<AcademyIllustratedStoryArt> createState() =>
      _AcademyIllustratedStoryArtState();
}

class _AcademyIllustratedStoryArtState extends State<AcademyIllustratedStoryArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this, duration: const Duration(seconds: 9),
  )..repeat();

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: AspectRatio(
      aspectRatio: 360 / 210,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _motion,
          builder: (context, child) => CustomPaint(
            painter: _StoryPainter(
              widget.scene, widget.page, _motion.value,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    ),
  );
}

class _StoryPainter extends CustomPainter {
  const _StoryPainter(this.scene, this.page, this.phase);
  final int scene;
  final int page;
  final double phase;

  static const palettes = <List<Color>>[
    [Color(0xFFFAAD9C), Color(0xFFFCE4B5), Color(0xFF8DB9AD)],
    [Color(0xFF426475), Color(0xFF9AD4B2), Color(0xFFE9BC76)],
    [Color(0xFFF2B36B), Color(0xFFFBE4AD), Color(0xFF9DC0A5)],
    [Color(0xFF5C77AD), Color(0xFF9CC9D6), Color(0xFFF5C783)],
    [Color(0xFF76A9B1), Color(0xFFB5D5C1), Color(0xFFF4D48F)],
    [Color(0xFF182C68), Color(0xFF354A82), Color(0xFF95BCB6)],
  ];

  void _box(Canvas c, double x, double y, double w, double h, Color color,
      {double radius = 0}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h),
      Radius.circular(radius)), Paint()..color = color);
  }

  void _circle(Canvas c, double x, double y, double radius, Color color) {
    c.drawCircle(Offset(x, y), radius, Paint()..color = color);
  }

  void _line(Canvas c, Offset a, Offset b, Color color, double width) {
    c.drawLine(a, b, Paint()
      ..color = color ..strokeWidth = width ..strokeCap = StrokeCap.round);
  }

  void _character(Canvas c, double x, double y, Color coat,
      {bool longHair = false}) {
    _box(c, x - 13, y + 15, 26, 41, coat, radius: 10);
    _line(c, Offset(x - 7, y + 53), Offset(x - 7, y + 65),
        const Color(0xFF294352), 5);
    _line(c, Offset(x + 7, y + 53), Offset(x + 7, y + 65),
        const Color(0xFF294352), 5);
    if (longHair) _circle(c, x, y + 2, 18, const Color(0xFF493C4C));
    _circle(c, x, y, 14, const Color(0xFFFFD2AA));
    c.drawArc(Rect.fromCenter(center: Offset(x, y - 5), width: 29, height: 27),
      math.pi, math.pi, false, Paint()
      ..color = const Color(0xFF493C4C)
      ..strokeWidth = 8 ..style = PaintingStyle.stroke);
    _circle(c, x - 5, y + 2, 1.4, const Color(0xFF263F47));
    _circle(c, x + 5, y + 2, 1.4, const Color(0xFF263F47));
    c.drawArc(Rect.fromCenter(center: Offset(x, y + 5), width: 9, height: 7),
      0, math.pi, false, Paint()
      ..color = const Color(0xFF984A52)
      ..strokeWidth = 1.5 ..style = PaintingStyle.stroke);
  }

  void _tree(Canvas c, double x, double y, double scale) {
    _box(c, x - 5 * scale, y, 10 * scale, 37 * scale,
        const Color(0xFF82654F), radius: 2);
    for (final p in [
      Offset(-15 * scale, 0), Offset(14 * scale, -7 * scale),
      Offset(0, -19 * scale),
    ]) {
      _circle(c, x + p.dx, y + p.dy, 22 * scale,
          const Color(0xFF387E70));
    }
  }

  void _book(Canvas c, double x, double y, {bool open = false}) {
    _box(c, x + 3, y + 4, 37, 44, const Color(0xFF173E56), radius: 3);
    _box(c, x, y, 37, 44, open ? const Color(0xFFFFF6DB)
        : const Color(0xFF4385C1), radius: 3);
    _line(c, Offset(x + 7, y + 9), Offset(x + 7, y + 37),
      const Color(0xFFEDC66D), 2);
    if (open) _line(c, Offset(x + 18, y + 4), Offset(x + 18, y + 39),
      const Color(0xFF9AB1B1), 1);
  }

  void _room(Canvas c) {
    _box(c, 0, 160, 360, 50, const Color(0xFFD5BA9B));
    _box(c, 24, 28, 78, 95, const Color(0xFFFEF4E7), radius: 7);
    _box(c, 33, 36, 60, 78, const Color(0xFFA1C7C8), radius: 3);
    _line(c, const Offset(63, 37), const Offset(63, 114),
      const Color(0xFFFDF4DE), 5);
    _box(c, 247, 27, 75, 139, const Color(0xFF976A60), radius: 6);
    for (final y in [54.0, 95, 135]) {
      _box(c, 256, y, 57, 5, const Color(0xFF563E44), radius: 2);
      for (var i = 0; i < 4; i++) {
        _box(c, 262.0 + i * 13, y - 22, 8, 22,
          [const Color(0xFF4C879C), const Color(0xFFE6B867),
           const Color(0xFF659778), const Color(0xFFC87874)][i], radius: 1);
      }
    }
  }

  void _kitchen(Canvas c) {
    _box(c, 0, 165, 360, 45, const Color(0xFFD9B58A));
    _box(c, 31, 41, 93, 79, const Color(0xFFFFF7E4), radius: 10);
    _box(c, 40, 49, 74, 62, const Color(0xFF90CFDB), radius: 4);
    _box(c, 218, 48, 108, 100, const Color(0xFFE0BEB1), radius: 7);
    _box(c, 217, 142, 109, 9, const Color(0xFF99735D), radius: 2);
    _box(c, 98, 147, 135, 11, const Color(0xFF936857), radius: 5);
    _box(c, 116, 154, 7, 49, const Color(0xFF936857));
    _box(c, 211, 154, 7, 49, const Color(0xFF936857));
    _circle(c, 174, 140, 15, const Color(0xFFF9E9C5));
    _box(c, 160, 130, 28, 10, const Color(0xFFD1A35B), radius: 5);
  }

  void _city(Canvas c) {
    for (final b in [
      [15.0, 85, 63.0, 83], [90, 44, 83, 128],
      [194, 71, 54, 100], [258, 38, 87, 134],
    ]) {
      _box(c, b[0].toDouble(), b[1].toDouble(), b[2].toDouble(), b[3].toDouble(),
          const Color(0xFFE9CFB0), radius: 6);
      for (var y = b[1] + 15; y < b[1] + b[3] - 15; y += 22) {
        for (var x = b[0] + 12; x < b[0] + b[2] - 8; x += 20) {
          _box(c, x.toDouble(), y.toDouble(), 9, 14,
              const Color(0xFF83AEB1), radius: 2);
        }
      }
    }
    _box(c, 0, 176, 360, 34, const Color(0xFFC1A996));
    _box(c, 282, 112, 37, 64, const Color(0xFF4080AD), radius: 3);
    _circle(c, 300, 126, 11, const Color(0xFFFFD77A));
  }

  void _garden(Canvas c) {
    _box(c, 0, 157, 360, 53, const Color(0xFF244F5D));
    for (final t in [[35.0, 98.0, 1.0], [296.0, 75.0, 1.4],
      [335.0, 122.0, .8]]) {
      _tree(c, t[0], t[1], t[2]);
    }
    for (var i = 0; i < 9; i++) {
      final x = 24.0 + i * 39;
      final y = 183.0 + math.sin(i * 1.9) * 12;
      _line(c, Offset(x, 210), Offset(x, y),
          const Color(0xFF72A981), 2);
      _circle(c, x, y, 4.8,
          i.isEven ? const Color(0xFFF3B7A5) : const Color(0xFFF5D27E));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.save();
    canvas.scale(size.width / 360, size.height / 210);
    final pal = palettes[scene % palettes.length];
    canvas.drawRect(const Rect.fromLTWH(0, 0, 360, 210),
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [pal[0], pal[1], pal[2]],
      ).createShader(const Rect.fromLTWH(0, 0, 360, 210)));

    if (scene == 0 || scene == 1) {
      _room(canvas);
      _character(canvas, 147, 107, const Color(0xFFD76D7A), longHair: true);
      _character(canvas, 205, 113, const Color(0xFF74A8A0));
      _book(canvas, page.isEven ? 181 : 222, 131, open: scene == 1);
    } else if (scene == 2) {
      _kitchen(canvas);
      _character(canvas, 79, 102, const Color(0xFFCD738B), longHair: true);
      _circle(canvas, 270, 166, 15, const Color(0xFF887D77));
      _circle(canvas, 264, 164, 2, Colors.white);
      _circle(canvas, 276, 164, 2, Colors.white);
    } else if (scene == 3) {
      _box(canvas, 0, 172, 360, 38, const Color(0xFF68798F));
      _box(canvas, 55, 92, 261, 91, const Color(0xFFF0CB77), radius: 18);
      _box(canvas, 85, 102, 81, 48, const Color(0xFF9CC8D1), radius: 6);
      _box(canvas, 176, 102, 85, 48, const Color(0xFF9CC8D1), radius: 6);
      _circle(canvas, 112, 180, 22, const Color(0xFF405161));
      _circle(canvas, 257, 180, 22, const Color(0xFF405161));
      for (var i = 0; i < 19; i++) {
        final x = (i * 29 + 9 + phase * 55) % 370;
        _line(canvas, Offset(x, (i * 31 + phase * 95) % 156),
          Offset(x - 5, (i * 31 + phase * 95) % 156 + 10),
          const Color(0x99F0F7FD), 2);
      }
    } else if (scene == 4) {
      _city(canvas);
      _character(canvas, 186, 128, const Color(0xFF6B83BC));
    } else {
      _garden(canvas);
      _circle(canvas, 73, 47, 21, const Color(0xFFFFE6B4));
      _character(canvas, 174, 121, const Color(0xFF9E82BF), longHair: true);
      _character(canvas, 220, 116, const Color(0xFF8BA4A9));
    }

    for (var i = 0; i < 11; i++) {
      final x = (23.0 + i * 31.7 + math.sin(phase * math.pi * 2 + i) * 6)
          .clamp(5.0, 355.0).toDouble();
      final y = (31.0 + (i * 17 + phase * 33) % 118);
      _circle(canvas, x, y, i.isEven ? 2.4 : 1.4,
          (scene == 5 ? const Color(0xFFFFE7A3) :
              const Color(0xFFFFFCDF)).withValues(alpha: .7));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StoryPainter oldDelegate) =>
      oldDelegate.scene != scene || oldDelegate.page != page ||
      oldDelegate.phase != phase;
}
