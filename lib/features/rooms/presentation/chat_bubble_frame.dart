import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/chat_bubble_catalog.dart';

/// One responsive material for the shop, DMs, rooms and live comments.
/// Decorations keep their size when the text wraps or the font is enlarged.
class WorldVoiceBubbleFrame extends StatelessWidget {
  const WorldVoiceBubbleFrame({
    required this.design,
    required this.child,
    this.compact = false,
    this.showSignature = false,
    super.key,
  });
  final ChatBubbleDesign design;
  final Widget child;
  final bool compact, showSignature;

  @override
  Widget build(BuildContext context) {
    final premium = design.tier == ChatBubbleTier.royal || design.isVip;
    final radius = BorderRadius.only(
      topLeft: Radius.circular(compact ? 16 : 24),
      topRight: Radius.circular(compact ? 16 : 24),
      bottomLeft: Radius.circular(compact ? 16 : 24),
      bottomRight: Radius.circular(compact ? 7 : 11),
    );
    final rim = design.accent;
    final dark = Color.lerp(design.secondary, const Color(0xFF020A12), .58)!;
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            const BoxShadow(
              color: Color(0x38000000),
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
            BoxShadow(
              color: rim.withValues(alpha: premium ? .19 : .1),
              blurRadius: premium ? 10 : 6,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                rim,
                const Color(0xFFFFF9E9),
                rim,
                Color.lerp(rim, Colors.black, .65)!,
                rim,
                const Color(0xFFFFF9E9),
                rim,
              ],
              stops: const [0, .13, .26, .48, .73, .87, 1],
            ),
          ),
          child: ClipRRect(
            borderRadius: radius.subtract(BorderRadius.circular(1.5)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(design.primary, Colors.black, .25)!,
                    dark,
                    Color.lerp(design.secondary, Colors.black, .28)!,
                    design.primary,
                  ],
                  stops: const [0, .45, .86, 1],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _GlassLight(rim, radius)),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _ornament(Alignment.topLeft),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _ornament(Alignment.bottomRight),
                  ),
                  Padding(
                    // Reserve horizontal space for the corner jewelry even
                    // for one-word messages and translated multiline text.
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 24 : 32,
                      vertical: compact ? 10 : 15,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showSignature) ...[
                          Text(
                            'WorldVoice',
                            style: TextStyle(
                              color: rim,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: .5,
                            ),
                          ),
                          const SizedBox(height: 5),
                        ],
                        DefaultTextStyle.merge(
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.38,
                            shadows: [
                              Shadow(color: Color(0x66000000), blurRadius: 2),
                            ],
                          ),
                          child: IconTheme.merge(
                            data: const IconThemeData(color: Colors.white),
                            child: child,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ornament(Alignment alignment) {
    final scale = compact ? .17 : .23;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: SizedBox(
          width: 145 * scale,
          height: 140 * scale,
          child: ClipRect(
            child: OverflowBox(
              alignment: alignment,
              minWidth: 720 * scale,
              maxWidth: 720 * scale,
              minHeight: 260 * scale,
              maxHeight: 260 * scale,
              child: SvgPicture.asset(
                'assets/chat_bubbles/${design.id}.svg',
                width: 720 * scale,
                height: 260 * scale,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Static highlights: no per-message animation controllers, blur filters or
/// repeating flashes in busy rooms. The middle stays dark for legibility.
class _GlassLight extends CustomPainter {
  const _GlassLight(this.accent, this.radius);
  final Color accent;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = rect.deflate(2);
    if (inset.isEmpty) return;
    canvas.drawRRect(
      radius.toRRect(inset),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: .65),
            accent.withValues(alpha: .03),
            accent.withValues(alpha: .5),
          ],
          stops: const [0, .4, 1],
        ).createShader(rect),
    );
    final sheen = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, 7)
      ..quadraticBezierTo(size.width * .45, 19, 0, 8)
      ..close();
    canvas.drawPath(
      sheen,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: .23),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, 19)),
    );
    final bottom = Rect.fromLTWH(0, size.height - 5, size.width, 5);
    canvas.drawRect(
      bottom,
      Paint()
        ..shader = LinearGradient(
          colors: [
            accent.withValues(alpha: 0),
            accent.withValues(alpha: .22),
            accent.withValues(alpha: 0),
          ],
        ).createShader(bottom),
    );
  }

  @override
  bool shouldRepaint(_GlassLight oldDelegate) =>
      accent != oldDelegate.accent || radius != oldDelegate.radius;
}
