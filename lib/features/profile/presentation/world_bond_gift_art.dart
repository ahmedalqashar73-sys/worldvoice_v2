import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Resolution-independent, original WorldBond artwork. A single short shimmer
/// runs on appearance, with no network assets or perpetual offscreen ticker.
class WorldBondGiftArt extends StatelessWidget {
  const WorldBondGiftArt({required this.level, this.size = 76, super.key});
  final int level;
  final double size;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero : const Duration(milliseconds: 1800),
      builder: (context, value, child) => CustomPaint(
        size: Size.square(size),
        painter: _BondArtPainter(level, value),
      ),
    ),
  );
}

class _BondArtPainter extends CustomPainter {
  const _BondArtPainter(this.level, this.phase);
  final int level;
  final double phase;
  static const gold = Color(0xFFFFD77D);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final tint = switch (level) {
      1 => const Color(0xFF21DCA4),
      2 => const Color(0xFFF1B649),
      3 => const Color(0xFFB9A5FF),
      _ => const Color(0xFFE87ABF),
    };
    final rect = const Rect.fromLTWH(0, 0, 100, 100);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(22)),
      Paint()..shader = RadialGradient(colors: [tint.withValues(alpha: .45),
        const Color(0xFF062E26)]).createShader(rect));
    final line = Paint()..color = gold..style = PaintingStyle.stroke
      ..strokeWidth = 1.4..strokeCap = StrokeCap.round;
    canvas.drawCircle(const Offset(50, 50), 42, line);
    void jewel(double x, double y, double r, Color color) {
      final shape = Path()..moveTo(x, y-r)..lineTo(x+r*.7, y)
        ..lineTo(x, y+r)..lineTo(x-r*.7, y)..close();
      canvas.drawPath(shape, Paint()..shader = LinearGradient(
        colors: [Colors.white, color, color.withValues(alpha: .5)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: Offset(x,y), radius:r)));
      canvas.drawPath(shape,line);
      canvas.drawLine(Offset(x-r*.7,y),Offset(x+r*.7,y),line);
      canvas.drawLine(Offset(x,y-r),Offset(x,y+r),line);
    }
    switch (level) {
      case 1:
        for (final x in [39.0, 61.0]) {
          canvas.drawOval(Rect.fromCenter(center: Offset(x,57),width:31,height:34),
            Paint()..color=gold..style=PaintingStyle.stroke..strokeWidth=4);
        }
        jewel(50,35,17,tint);
      case 2:
        final bridge = Path()..moveTo(18,62)..quadraticBezierTo(50,23,82,62);
        canvas.drawPath(bridge,Paint()..color=gold..style=PaintingStyle.stroke..strokeWidth=5);
        canvas.drawLine(const Offset(18,67),const Offset(82,67),line);
        for (final x in [22.0,32.0,42.0,58.0,68.0,78.0]) {
          canvas.drawLine(Offset(x,50+(x-50).abs()*.35),Offset(x,67),line);
        }
        jewel(50,29,9,tint);
        canvas.drawArc(const Rect.fromLTWH(20,65,60,16),0,math.pi,false,line);
      case 3:
        canvas.drawOval(const Rect.fromLTWH(17,42,66,27),line);
        jewel(32,52,17,const Color(0xFF81D8FF));
        jewel(68,52,17,const Color(0xFFDFBBFF));
        jewel(50,45,28,tint);
      default:
        final crown = Path()..moveTo(24,62)..lineTo(18,35)..lineTo(36,45)
          ..lineTo(50,24)..lineTo(64,45)..lineTo(82,35)..lineTo(76,62)..close();
        canvas.drawPath(crown,Paint()..shader=const LinearGradient(
          colors:[Color(0xFFB47A24),Color(0xFFFFEDAF),Color(0xFFD39B38)],
        ).createShader(const Rect.fromLTWH(18,24,64,42)));
        canvas.drawPath(crown,line);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24,65,52,9),
          const Radius.circular(4)),Paint()..color=gold);
        jewel(50,52,10,tint);
    }
    final sparkle = Paint()..color=Colors.white.withValues(
      alpha:.3+.7*math.sin(phase*math.pi))..strokeWidth=1.5;
    for (final point in [const Offset(20,22),const Offset(79,77),const Offset(77,19)]) {
      canvas.drawLine(point-const Offset(4,0),point+const Offset(4,0),sparkle);
      canvas.drawLine(point-const Offset(0,4),point+const Offset(0,4),sparkle);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BondArtPainter old) =>
      old.level != level || old.phase != phase;
}
