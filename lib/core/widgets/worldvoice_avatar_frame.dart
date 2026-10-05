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
    'free_royal_gold',
    'free_emerald_crown',
    'free_crystal_blue',
    'free_rose_luxe',
    'free_cosmic_voice',
  ];

  static bool isFree(String? frameId) =>
      frameId != null && freeFrameIds.contains(frameId);

  static bool isPremium(String? frameId) =>
      frameId?.startsWith('frame__') == true;

  static String label(String frameId, {required bool ar}) {
    switch (frameId) {
      case 'free_clean_white':
        return ar ? 'أبيض نقي' : 'Clean White';
      case 'free_soft_green':
        return ar ? 'أخضر ناعم' : 'Soft Green';
      case 'free_sky_blue':
        return ar ? 'سماوي' : 'Sky Blue';
      case 'free_silver':
        return ar ? 'فضي' : 'Silver';
      case 'free_minimal_glow':
        return ar ? 'وهج بسيط' : 'Minimal Glow';
      case 'free_royal_gold':
        return ar ? 'الذهبي الملكي' : 'Royal Gold';
      case 'free_emerald_crown':
        return ar ? 'تاج الزمرد' : 'Emerald Crown';
      case 'free_crystal_blue':
        return ar ? 'كريستال أزرق' : 'Crystal Blue';
      case 'free_rose_luxe':
        return ar ? 'وردة فاخرة' : 'Rose Luxe';
      case 'free_cosmic_voice':
        return ar ? 'فويس كوني' : 'Cosmic Voice';
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
        return const [Color(0xFFFFFFFF), Color(0xFFDDE5E8)];
      case 'free_soft_green':
        return const [Color(0xFF6BE7B1), Color(0xFF1C8C68)];
      case 'free_sky_blue':
        return const [Color(0xFF8EDFFF), Color(0xFF338BC8)];
      case 'free_silver':
        return const [Color(0xFFF3F5F7), Color(0xFF9AA8B1)];
      case 'free_minimal_glow':
        return const [Color(0xFF7CF6C5), Color(0xFF7BBEFF)];
      case 'free_royal_gold':
        return const [
          Color(0xFFFFF1B0),
          Color(0xFFE4B83D),
          Color(0xFF8E5D08),
          Color(0xFFFFD86B),
        ];
      case 'free_emerald_crown':
        return const [
          Color(0xFFBFFFE2),
          Color(0xFF1DD68F),
          Color(0xFF087554),
          Color(0xFFFFD870),
        ];
      case 'free_crystal_blue':
        return const [
          Color(0xFFFFFFFF),
          Color(0xFF99E4FF),
          Color(0xFF4C9FFF),
          Color(0xFFD9F7FF),
        ];
      case 'free_rose_luxe':
        return const [
          Color(0xFFFFE0EF),
          Color(0xFFFF8FC7),
          Color(0xFFC84686),
          Color(0xFFFFD6A6),
        ];
      case 'free_cosmic_voice':
        return const [
          Color(0xFF8FFFE3),
          Color(0xFF60B7FF),
          Color(0xFFB86BFF),
          Color(0xFFFF73BE),
        ];
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
          const {
            'free_minimal_glow',
            'free_royal_gold',
            'free_emerald_crown',
            'free_crystal_blue',
            'free_rose_luxe',
            'free_cosmic_voice',
          }.contains(widget.frameId));

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
    final crown = id == 'frame__golden_crown' ||
        id == 'free_royal_gold' ||
        id == 'free_emerald_crown';

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
              if (id == 'frame__diamond_shine' ||
                  id == 'free_crystal_blue' ||
                  id == 'free_cosmic_voice')
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
