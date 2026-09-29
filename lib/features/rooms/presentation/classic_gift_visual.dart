import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/room_feature_models.dart';

/// Framed-free emerald presentation for the shared catalog. A published
/// HTTPS image/GIF takes precedence over the built-in preview glyph.
class ClassicGiftVisual extends StatefulWidget {
  const ClassicGiftVisual({
    required this.gift,
    this.size = 94,
    this.animate = false,
    super.key,
  });

  final RoomGiftCatalogItem gift;
  final double size;
  final bool animate;

  @override
  State<ClassicGiftVisual> createState() => _ClassicGiftVisualState();
}

class _ClassicGiftVisualState extends State<ClassicGiftVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: Duration(milliseconds:
        widget.gift.effectType == 'phoenix' ? 2200 : 1750),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _motion.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ClassicGiftVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _motion.repeat(reverse: true);
      } else {
        _motion.stop();
        _motion.value = 0.5;
      }
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  Widget _poster() {
    final url = widget.gift.previewUrl?.trim();
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri != null && uri.scheme == 'https' && uri.hasAuthority) {
      return Image.network(
        uri.toString(),
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    if (widget.gift.id.startsWith('classic_') &&
        RegExp(r'^classic_[a-z0-9_]+$').hasMatch(widget.gift.id)) {
      return SvgPicture.asset(
        'assets/gifts/art/${widget.gift.id}.svg',
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Text(
        widget.gift.emoji ?? '🎁',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: widget.size * .49,
          shadows: [
            Shadow(
              color: const Color(0xFFFFD879).withValues(alpha: .42),
              blurRadius: widget.size * .12,
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _motion,
        builder: (context, _) {
          final v = widget.animate ? _motion.value : .5;
          final wave = math.sin(2 * math.pi * v);
          final effect = widget.gift.effectType ?? '';
          final flying = const {
            'fly', 'float', 'drift', 'butterfly', 'glide', 'flap',
            'deer', 'phoenix',
          }.contains(effect);
          final spinning = const {
            'orbit', 'pendulum', 'ring', 'fan', 'phoenix',
          }.contains(effect);
          final pulse = const {
            'pulse', 'heart', 'prism', 'crown', 'burst',
            'phoenix', 'unwrap',
          }.contains(effect);
          final dx = effect == 'butterfly' || effect == 'phoenix'
              ? wave * widget.size * .11
              : effect == 'drift' ? wave * widget.size * .07 : 0.0;
          final dy = flying ? -widget.size * (.03 + .09 * v)
              : (pulse ? -widget.size * .018 * wave : 0.0);
          final rotation = spinning
              ? wave * (effect == 'phoenix' ? .17 : .08)
              : (effect == 'butterfly' ? wave * .05 : 0.0);
          final zoom = 1 + (pulse ? (.13 * v) : .035 * v);
          final glow = .38 + .28 * v;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Radial glow is part of the gift, not a tile/background/frame.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF25D992).withValues(alpha: glow),
                        const Color(0xFF0B9D69).withValues(alpha: .11),
                        Colors.transparent,
                      ],
                      stops: const [0, .49, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: widget.size * (.11 + .04 * v),
                right: widget.size * .11,
                child: Opacity(
                  opacity: (.55 + .4 * v).clamp(0.0, 1.0),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: widget.size * .13,
                    color: const Color(0xFFFFE3A0),
                  ),
                ),
              ),
              Positioned(
                bottom: widget.size * (.18 - .03 * v),
                left: widget.size * .09,
                child: Opacity(
                  opacity: (.4 + .35 * (1 - v)).clamp(0.0, 1.0),
                  child: Icon(
                    Icons.star_rounded,
                    size: widget.size * .09,
                    color: const Color(0xFF9BF5C4),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.rotate(
                  angle: rotation,
                  child: Transform.scale(
                    scale: zoom,
                    child: SizedBox.square(
                      dimension: widget.size * .78,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox.square(
                          dimension: widget.size * .75,
                          child: Center(child: _poster()),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
