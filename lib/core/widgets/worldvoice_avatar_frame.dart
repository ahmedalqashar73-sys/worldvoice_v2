import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

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
    'free_art_01', 'free_art_02', 'free_art_03', 'free_art_04',
  ];

  /// 33 artwork frames, packed as a transparent 6x6 WebP atlas.
  static const String artworkAsset = 'assets/frames/frames_192.webp';
  static const List<int> artworkPricesCoins = <int>[
    0,
    0,
    0,
    0,
    180,
    220,
    240,
    260,
    260,
    300,
    350,
    280,
    340,
    320,
    360,
    360,
    420,
    440,
    420,
    450,
    480,
    500,
    520,
    540,
    480,
    540,
    580,
    600,
    650,
    680,
    700,
    750,
    850
  ];
  static const List<String> _artNamesEn = <String>[
    'Golden Tide',
    'Solar Crown',
    'Cosmic Orbit',
    'Moonlit Roses',
    'Neon Melody',
    'Ice Dragon',
    'Koi Garden',
    'Crystal Pulse',
    'Sakura Kitten',
    'Mecha Titan',
    'Azure Dragon',
    'Pink Blossom',
    'Royal Wings',
    'Ruby Roses',
    'Panda Paradise',
    'Royal Kitten',
    'Emerald Crown',
    'Midnight Roses',
    'Ice Queen',
    'Golden Clock',
    'Prism Star',
    'Peacock Jewel',
    'Heart of Roses',
    'Butterfly Gold',
    'Ocean Pearl',
    'White Tiger',
    'Phoenix Flame',
    'Emerald Dream',
    'Fire Dragon',
    'Violet Crown',
    'Crystal Princess',
    'Jungle Panther',
    'Pharaoh Gold'
  ];
  static const List<String> _artNamesAr = <String>[
    'المد الذهبي',
    'التاج الشمسي',
    'مدار المجرة',
    'ورود القمر',
    'لحن النيون',
    'تنين الجليد',
    'حديقة الكوي',
    'نبض الكريستال',
    'قطة الساكورا',
    'العملاق الآلي',
    'التنين الأزرق',
    'الزهرة الوردية',
    'أجنحة ملكية',
    'الورود الياقوتية',
    'جنة الباندا',
    'القطة الملكية',
    'التاج الزمردي',
    'ورود الليل',
    'ملكة الجليد',
    'الساعة الذهبية',
    'نجمة البلور',
    'جوهرة الطاووس',
    'قلب الورود',
    'الفراشة الذهبية',
    'لؤلؤة المحيط',
    'النمر الأبيض',
    'لهيب العنقاء',
    'الحلم الزمردي',
    'تنين النار',
    'التاج البنفسجي',
    'أميرة الكريستال',
    'نمر الغابة',
    'ذهب الفراعنة'
  ];

  static String artworkId(int index) {
    final code = (index + 1).toString().padLeft(2, '0');
    return index < 4 ? 'free_art_$code' : 'frame__art_$code';
  }

  static final List<String> premiumArtworkFrameIds =
      List<String>.unmodifiable(
        List<String>.generate(29, (index) => artworkId(index + 4)),
      );

  static int? artworkIndex(String? id) {
    final value = id?.trim() ?? '';
    final match = RegExp(r'^(free_art_|frame__art_)(\d{2})
      frameId != null && freeFrameIds.contains(frameId);

  static bool isPremium(String? frameId) =>
      frameId?.startsWith('frame__') == true;

  static String label(String frameId, {required bool ar}) {
    final i = artworkIndex(frameId);
    if (i != null) return ar ? _artNamesAr[i] : _artNamesEn[i];
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
    final artIndex = WorldVoiceAvatarFrame.artworkIndex(id);
    if (artIndex != null) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              // Keep the user photo inside the transparent central opening.
              Padding(
                padding: EdgeInsets.all(widget.size * .22),
                child: ClipOval(child: widget.child),
              ),
              if (artIndex >= 4 && _animated)
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD27D).withValues(
                          alpha: .14 +
                              .12 * math.sin(_controller.value * math.pi).abs(),
                        ),
                        blurRadius: widget.size * .14,
                      ),
                    ],
                  ),
                ),
              IgnorePointer(
                child: FutureBuilder<ui.Image>(
                  future: WorldVoiceAvatarFrame._artworkImage,
                  builder: (context, snapshot) {
                    final image = snapshot.data;
                    if (image == null) return const SizedBox.expand();
                    return RepaintBoundary(
                      child: CustomPaint(
                        painter: _WorldVoiceArtworkPainter(
                          image: image,
                          index: artIndex,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
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
)
        .firstMatch(value);
    if (match == null) return null;
    final i = int.parse(match.group(2)!) - 1;
    return i >= 0 && i < 33 && artworkId(i) == value ? i : null;
  }

  static bool isArtworkFrame(String? id) => artworkIndex(id) != null;
  static int artworkPrice(String id) {
    final index = artworkIndex(id);
    return index == null ? 0 : artworkPricesCoins[index];
  }

  static final Future<ui.Image> _artworkImage = _readArtwork();
  static Future<ui.Image> _readArtwork() async {
    final data = await rootBundle.load(artworkAsset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

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

class _WorldVoiceArtworkPainter extends CustomPainter {
  const _WorldVoiceArtworkPainter({required this.image, required this.index});
  final ui.Image image;
  final int index;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final cellWidth = image.width / 6;
    final cellHeight = image.height / 6;
    final source = Rect.fromLTWH(
      (index % 6) * cellWidth,
      (index ~/ 6) * cellHeight,
      cellWidth,
      cellHeight,
    );
    canvas.drawImageRect(
      image, source, Offset.zero & size,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _WorldVoiceArtworkPainter old) =>
      old.image != image || old.index != index;
}
