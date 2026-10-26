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
    'free_clean_white',
    'free_soft_green',
    'free_sky_blue',
    'free_silver',
  ];

  /// 33 signature frames; IDs and prices remain compatible with owned items.
  static const String artworkAsset = 'assets/frames/signature_frames.webp';
  static const List<int> artworkPricesCoins = <int>[
    0,
    360,
    280,
    300,
    240,
    520,
    280,
    310,
    0,
    420,
    560,
    250,
    420,
    380,
    0,
    320,
    460,
    370,
    490,
    370,
    400,
    480,
    440,
    360,
    0,
    520,
    580,
    450,
    620,
    420,
    520,
    640,
    590,
  ];
  static const List<String> _artNamesEn = <String>[
    'Royal Crescent',
    'Solar Crown',
    'Cosmic Orbit',
    'Moonlight Roses',
    'Neon Melody',
    'Frozen Dragon',
    'Koi Paradise',
    'Cyber Knight',
    'Pink Kitten',
    'Royal Engine',
    'Azure Dragon',
    'Sakura Princess',
    'Royal Eagle',
    'Ruby Thorns',
    'Panda Garden',
    'Pearl Kitty',
    'Emerald Crown',
    'Midnight Roses',
    'Crystal Queen',
    'Clockwork Gold',
    'Prism Future',
    'Peacock Majesty',
    'Ruby Romance',
    'Butterfly Dream',
    'Ocean Pearls',
    'Arctic Wolf',
    'Golden Phoenix',
    'Emerald Bloom',
    'Lava King',
    'Violet Shadow',
    'Opal Kingdom',
    'Jungle Panther',
    'Pharaoh Gold',
  ];
  static const List<String> _artNamesAr = <String>[
    'هلال ملكي',
    'تاج الشمس',
    'مدار المجرة',
    'ورود القمر',
    'نغمات النيون',
    'التنين الجليدي',
    'جنة أسماك الكوي',
    'الفارس الإلكتروني',
    'القطة الوردية',
    'المحرك الملكي',
    'التنين الأزرق',
    'أميرة الساكورا',
    'النسر الملكي',
    'أشواك الياقوت',
    'حديقة الباندا',
    'القطة اللؤلؤية',
    'تاج الزمرد',
    'ورود منتصف الليل',
    'ملكة الكريستال',
    'الساعة الذهبية',
    'كريستال المستقبل',
    'الطاووس الملكي',
    'ورود الحب الحمراء',
    'حلم الفراشات',
    'لآلئ المحيط',
    'الذئب القطبي',
    'العنقاء الذهبية',
    'أزهار الزمرد',
    'ملك الحمم',
    'الظل البنفسجي',
    'مملكة الأوبال',
    'نمر الأدغال',
    'ذهب الفراعنة',
  ];

  static const Map<int, String> _freeArtwork = <int, String>{
    0: 'free_clean_white',
    8: 'free_soft_green',
    14: 'free_sky_blue',
    24: 'free_silver',
  };

  static String artworkId(int index) {
    if (index < 0 || index >= 33) throw RangeError.range(index, 0, 32);
    final freeId = _freeArtwork[index];
    if (freeId != null) return freeId;
    final code = (index + 1).toString().padLeft(2, '0');
    return 'frame__wv_frame_$code';
  }

  static final List<String> premiumArtworkFrameIds =
      List<String>.unmodifiable(<String>[
        for (var index = 0; index < 33; index++)
          if (!_freeArtwork.containsKey(index)) artworkId(index),
      ]);

  static int? artworkIndex(String? id) {
    final value = id?.trim() ?? '';
    for (final entry in _freeArtwork.entries) {
      if (entry.value == value) return entry.key;
    }
    final match = RegExp(r'^frame__wv_frame_(\d{2})$').firstMatch(value);
    if (match == null) return null;
    final index = int.parse(match.group(1)!) - 1;
    return index >= 0 && index < 33 && !_freeArtwork.containsKey(index)
        ? index
        : null;
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
      frameId != null &&
      (freeFrameIds.contains(frameId) ||
          const <String>{
            'free_clean_white',
            'free_soft_green',
            'free_sky_blue',
            'free_silver',
            'free_minimal_glow',
          }.contains(frameId));

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
  State<WorldVoiceAvatarFrame> createState() => _WorldVoiceAvatarFrameState();
}

class _WorldVoiceAvatarFrameState extends State<WorldVoiceAvatarFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool _reduceMotion = false;

  bool get _animated =>
      widget.animate &&
      !_reduceMotion &&
      (WorldVoiceAvatarFrame.isArtworkFrame(widget.frameId) ||
          WorldVoiceAvatarFrame.isPremium(widget.frameId) ||
          widget.frameId == 'free_minimal_glow');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );
    if (_animated) _controller.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_animated && TickerMode.valuesOf(context).enabled) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void didUpdateWidget(covariant WorldVoiceAvatarFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_animated &&
        TickerMode.valuesOf(context).enabled &&
        !_controller.isAnimating) {
      _controller.repeat();
    } else if ((!_animated || !TickerMode.valuesOf(context).enabled) &&
        _controller.isAnimating) {
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
      return RepaintBoundary(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The portrait is never animated or covered by the artwork.
              Padding(
                padding: EdgeInsets.all(widget.size * .12),
                child: ClipOval(child: widget.child),
              ),
              IgnorePointer(
                child: ExcludeSemantics(
                  child: ClipPath(
                    clipper: const WorldVoiceFrameRingClipper(),
                    child: FutureBuilder<ui.Image>(
                      future: WorldVoiceAvatarFrame._artworkImage,
                      builder: (context, snapshot) => CustomPaint(
                        painter: _WorldVoiceArtworkPainter(
                          image: snapshot.data,
                          index: artIndex,
                          progress: _controller,
                          animated: _animated,
                        ),
                      ),
                    ),
                  ),
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
                      Shadow(color: Color(0x99000000), blurRadius: 4),
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

/// The center is an enforced no-paint region, including at every animation phase.
class WorldVoiceFrameRingClipper extends CustomClipper<Path> {
  const WorldVoiceFrameRingClipper();
  @override
  Path getClip(Size size) {
    final center = size.center(Offset.zero);
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: center, radius: size.shortestSide * .5))
      ..addOval(
        Rect.fromCircle(center: center, radius: size.shortestSide * .38),
      );
  }

  @override
  bool shouldReclip(WorldVoiceFrameRingClipper oldClipper) => false;
}

class _WorldVoiceArtworkPainter extends CustomPainter {
  _WorldVoiceArtworkPainter({
    required this.image,
    required this.index,
    required this.progress,
    required this.animated,
  }) : super(repaint: progress);
  final ui.Image? image;
  final int index;
  final Animation<double> progress;
  final bool animated;

  static const accents = [
    Color(0xFFE4E9FF),
    Color(0xFFFFD577),
    Color(0xFF8CEFFF),
    Color(0xFFA9D4FF),
    Color(0xFFF1A2FF),
    Color(0xFF9BDFFF),
    Color(0xFFFFC86B),
    Color(0xFF53E3FF),
    Color(0xFFFFB8D9),
    Color(0xFFFFD980),
    Color(0xFF67CEFF),
    Color(0xFFFFB2D4),
    Color(0xFFE2F3FF),
    Color(0xFFFF7597),
    Color(0xFFB2ED9C),
    Color(0xFFFFDCEB),
    Color(0xFF76EDBB),
    Color(0xFFC9CAED),
    Color(0xFFADE8FF),
    Color(0xFFF4D58E),
    Color(0xFFD8B9FF),
    Color(0xFF6EECDD),
    Color(0xFFFF91A9),
    Color(0xFFE9B7FF),
    Color(0xFFB1F8F3),
    Color(0xFFD1E8FF),
    Color(0xFFFFBD68),
    Color(0xFFB4F2A0),
    Color(0xFFFF9476),
    Color(0xFFC1A2FF),
    Color(0xFFF5DFFF),
    Color(0xFFFFDA9E),
    Color(0xFFFFD264),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final center = size.center(Offset.zero);
    final d = size.shortestSide;
    final accent = accents[index];
    canvas.save();
    canvas.clipPath(const WorldVoiceFrameRingClipper().getClip(size));
    // Thin inner bezel joins the photograph to the jewelry without covering it.
    canvas.drawCircle(
      center,
      d * .388,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = d * .012
        ..color = accent.withValues(alpha: .8),
    );
    final art = image;
    if (art != null) {
      final w = art.width / 6, h = art.height / 6;
      canvas.drawImageRect(
        art,
        Rect.fromLTWH((index % 6) * w, (index ~/ 6) * h, w, h),
        Offset.zero & size,
        Paint()..filterQuality = FilterQuality.high,
      );
    }
    if (animated) {
      final phase = progress.value * math.pi * 2;
      // Travel along the outer rim; the photo and sculpted artwork remain still.
      for (var i = 0; i < 3; i++) {
        final angle = phase + i * math.pi * 2 / 3 + index * .3;
        final r = d * (.435 + .012 * math.sin(phase + i));
        final point = center + Offset(math.cos(angle), math.sin(angle)) * r;
        final alpha = .4 + .5 * (.5 + .5 * math.sin(phase * 2 + i));
        canvas.drawCircle(
          point,
          d * .026,
          Paint()..color = accent.withValues(alpha: alpha * .22),
        );
        final pen = Paint()
          ..color = Color.lerp(
            accent,
            Colors.white,
            .7,
          )!.withValues(alpha: alpha)
          ..strokeWidth = math.max(.6, d * .008)
          ..strokeCap = StrokeCap.round;
        final extent = d * (i == 0 ? .022 : .014);
        canvas.drawLine(
          point - Offset(extent, 0),
          point + Offset(extent, 0),
          pen,
        );
        canvas.drawLine(
          point - Offset(0, extent),
          point + Offset(0, extent),
          pen,
        );
      }
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: d * .405),
        phase + index,
        .3,
        false,
        Paint()
          ..color = accent.withValues(alpha: .6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.7, d * .009)
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WorldVoiceArtworkPainter old) =>
      old.image != image || old.index != index || old.animated != animated;
}
