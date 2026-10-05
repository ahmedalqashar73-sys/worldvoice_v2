import 'dart:math' as math;

import 'package:flutter/material.dart';

class WorldVoiceAvatarFrame extends StatefulWidget {
  const WorldVoiceAvatarFrame({
    required this.child,
    required this.size,
    this.frameId,
    this.animate = true,
    super.key,
  });

  final Widget child;
  final double size;
  final String? frameId;
  final bool animate;

  static const List<String> freeFrameIds = <String>[
    'free_clean_white',
    'free_soft_green',
    'free_sky_blue',
    'free_silver',
    'free_minimal_glow',
  ];

  static bool isFree(String? frameId) =>
      frameId != null && freeFrameIds.contains(frameId);

  static bool isPremium(String? frameId) =>
      frameId?.startsWith('frame__') == true;

  static String label(String frameId, {required bool ar}) {
    switch (frameId) {
      case 'free_clean_white':
        return ar ? 'لؤلؤي ملكي' : 'Royal Pearl';
      case 'free_soft_green':
        return ar ? 'زمرد ناعم' : 'Emerald Glow';
      case 'free_sky_blue':
        return ar ? 'كريستال سماوي' : 'Sky Crystal';
      case 'free_silver':
        return ar ? 'فضي فاخر' : 'Luxury Silver';
      case 'free_minimal_glow':
        return ar ? 'هالة WorldVoice' : 'WorldVoice Aura';
      case 'frame__golden_crown':
        return ar ? 'التاج الذهبي' : 'Golden Crown';
      case 'frame__royal_emerald':
        return ar ? 'الزمرد الملكي' : 'Royal Emerald';
      case 'frame__diamond_shine':
        return ar ? 'لمعة الماس' : 'Diamond Shine';
      case 'frame__neon_voice':
        return ar ? 'نيون فويس' : 'Neon Voice';
      case 'frame__galaxy_ring':
        return ar ? 'حلقة المجرة' : 'Galaxy Ring';
      default:
        return ar ? 'إطار WorldVoice' : 'WorldVoice Frame';
    }
  }

  static List<Color> colorsFor(String? frameId) {
    switch (frameId) {
      case 'free_clean_white':
        return const [Color(0xFFFFFFFF), Color(0xFFFFE4A8), Color(0xFFD6DEE2)];
      case 'free_soft_green':
        return const [Color(0xFFBFFFE2), Color(0xFF25C98A), Color(0xFF0E6E50)];
      case 'free_sky_blue':
        return const [Color(0xFFFFFFFF), Color(0xFF8EDFFF), Color(0xFF398BD4)];
      case 'free_silver':
        return const [Color(0xFFFFFFFF), Color(0xFFD8DDE3), Color(0xFF8897A2)];
      case 'free_minimal_glow':
        return const [Color(0xFF7CF6C5), Color(0xFF7BBEFF), Color(0xFFC48CFF)];
      case 'frame__golden_crown':
        return const [
          Color(0xFFFFE79A),
          Color(0xFFFFC43D),
          Color(0xFFB77B08),
          Color(0xFFFFF1B9),
        ];
      case 'frame__royal_emerald':
        return const [
          Color(0xFFB8FFD9),
          Color(0xFF19B77A),
          Color(0xFF07563F),
          Color(0xFF75F4BD),
        ];
      case 'frame__diamond_shine':
        return const [
          Color(0xFFFFFFFF),
          Color(0xFFB8E9FF),
          Color(0xFF9C8CFF),
          Color(0xFFF6FFFF),
        ];
      case 'frame__neon_voice':
        return const [
          Color(0xFF52FFD0),
          Color(0xFF52A7FF),
          Color(0xFFFF62C6),
          Color(0xFF52FFD0),
        ];
      case 'frame__galaxy_ring':
        return const [
          Color(0xFF88A2FF),
          Color(0xFFB96DFF),
          Color(0xFFFF6DB2),
          Color(0xFF4BE7E0),
        ];
      default:
        return const [Color(0xFFE8EEF0), Color(0xFFBAC7CC)];
    }
  }

  @override
  State<WorldVoiceAvatarFrame> createState() =>
      _WorldVoiceAvatarFrameState();
}

class _WorldVoiceAvatarFrameState extends State<WorldVoiceAvatarFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _animated =>
      widget.animate &&
      (WorldVoiceAvatarFrame.isPremium(widget.frameId) ||
          widget.frameId == 'free_minimal_glow');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    if (_animated) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant WorldVoiceAvatarFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_animated && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!_animated && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.frameId;
    final colors = WorldVoiceAvatarFrame.colorsFor(id);
    final premium = WorldVoiceAvatarFrame.isPremium(id);
    final border = premium ? 4.5 : 3.2;
    final crown = id == 'frame__golden_crown';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final angle = _animated ? _controller.value * math.pi * 2 : 0.0;
        final glow = premium
            ? 10 + 5 * math.sin(_controller.value * math.pi * 2).abs()
            : id == 'free_minimal_glow'
                ? 7.0
                : 0.0;

        return SizedBox(
          width: widget.size,
          height: widget.size + (crown ? 10 : 0),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: widget.size,
                height: widget.size,
                padding: EdgeInsets.all(border),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: <Color>[...colors, colors.first],
                    transform: GradientRotation(angle),
                  ),
                  boxShadow: glow <= 0
                      ? null
                      : [
                          BoxShadow(
                            color: colors.first.withValues(alpha: .48),
                            blurRadius: glow,
                            spreadRadius: premium ? 1.6 : .6,
                          ),
                        ],
                ),
                child: ClipOval(child: widget.child),
              ),
              if (crown)
                Positioned(
                  top: -8,
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: widget.size * .28,
                    color: const Color(0xFFFFD65A),
                    shadows: const [
                      Shadow(
                        color: Color(0x99000000),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              if (id == 'frame__diamond_shine')
                Positioned(
                  top: widget.size * .04,
                  right: widget.size * .02,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: widget.size * .22,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
