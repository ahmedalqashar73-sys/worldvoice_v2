import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'package:flutter/material.dart';

class WorldVoiceFrameCatalogItem {
  const WorldVoiceFrameCatalogItem({
    required this.id,
    required this.atlasIndex,
    required this.name,
    required this.nameAr,
    required this.priceCoins,
  });

  final String id;
  final int atlasIndex;
  final String name;
  final String nameAr;
  final int priceCoins;

  bool get isFree => priceCoins == 0;
}

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

  // Four bundled frames are free. Preserve the legacy fifth for users
  // who equipped it before the artwork catalog was introduced.
  static const List<String> freeFrameIds = <String>[
    'free_clean_white',
    'free_soft_green',
    'free_sky_blue',
    'free_silver',
  ];

  static const List<WorldVoiceFrameCatalogItem> bundledFrames = [
    WorldVoiceFrameCatalogItem(id: 'free_clean_white', atlasIndex: 0, name: 'Royal Crescent', nameAr: 'هلال ملكي', priceCoins: 0),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_02', atlasIndex: 1, name: 'Solar Crown', nameAr: 'تاج الشمس', priceCoins: 360),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_03', atlasIndex: 2, name: 'Cosmic Orbit', nameAr: 'مدار المجرة', priceCoins: 280),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_04', atlasIndex: 3, name: 'Moonlight Roses', nameAr: 'ورود القمر', priceCoins: 300),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_05', atlasIndex: 4, name: 'Neon Melody', nameAr: 'نغمات النيون', priceCoins: 240),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_06', atlasIndex: 5, name: 'Frozen Dragon', nameAr: 'التنين الجليدي', priceCoins: 520),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_07', atlasIndex: 6, name: 'Koi Paradise', nameAr: 'جنة أسماك الكوي', priceCoins: 280),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_08', atlasIndex: 7, name: 'Cyber Knight', nameAr: 'الفارس الإلكتروني', priceCoins: 310),
    WorldVoiceFrameCatalogItem(id: 'free_soft_green', atlasIndex: 8, name: 'Pink Kitten', nameAr: 'القطة الوردية', priceCoins: 0),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_10', atlasIndex: 9, name: 'Royal Engine', nameAr: 'المحرك الملكي', priceCoins: 420),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_11', atlasIndex: 10, name: 'Azure Dragon', nameAr: 'التنين الأزرق', priceCoins: 560),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_12', atlasIndex: 11, name: 'Sakura Princess', nameAr: 'أميرة الساكورا', priceCoins: 250),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_13', atlasIndex: 12, name: 'Royal Eagle', nameAr: 'النسر الملكي', priceCoins: 420),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_14', atlasIndex: 13, name: 'Ruby Thorns', nameAr: 'أشواك الياقوت', priceCoins: 380),
    WorldVoiceFrameCatalogItem(id: 'free_sky_blue', atlasIndex: 14, name: 'Panda Garden', nameAr: 'حديقة الباندا', priceCoins: 0),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_16', atlasIndex: 15, name: 'Pearl Kitty', nameAr: 'القطة اللؤلؤية', priceCoins: 320),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_17', atlasIndex: 16, name: 'Emerald Crown', nameAr: 'تاج الزمرد', priceCoins: 460),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_18', atlasIndex: 17, name: 'Midnight Roses', nameAr: 'ورود منتصف الليل', priceCoins: 370),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_19', atlasIndex: 18, name: 'Crystal Queen', nameAr: 'ملكة الكريستال', priceCoins: 490),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_20', atlasIndex: 19, name: 'Clockwork Gold', nameAr: 'الساعة الذهبية', priceCoins: 370),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_21', atlasIndex: 20, name: 'Prism Future', nameAr: 'كريستال المستقبل', priceCoins: 400),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_22', atlasIndex: 21, name: 'Peacock Majesty', nameAr: 'الطاووس الملكي', priceCoins: 480),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_23', atlasIndex: 22, name: 'Ruby Romance', nameAr: 'ورود الحب الحمراء', priceCoins: 440),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_24', atlasIndex: 23, name: 'Butterfly Dream', nameAr: 'حلم الفراشات', priceCoins: 360),
    WorldVoiceFrameCatalogItem(id: 'free_silver', atlasIndex: 24, name: 'Ocean Pearls', nameAr: 'لآلئ المحيط', priceCoins: 0),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_26', atlasIndex: 25, name: 'Arctic Wolf', nameAr: 'الذئب القطبي', priceCoins: 520),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_27', atlasIndex: 26, name: 'Golden Phoenix', nameAr: 'العنقاء الذهبية', priceCoins: 580),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_28', atlasIndex: 27, name: 'Emerald Bloom', nameAr: 'أزهار الزمرد', priceCoins: 450),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_29', atlasIndex: 28, name: 'Lava King', nameAr: 'ملك الحمم', priceCoins: 620),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_30', atlasIndex: 29, name: 'Violet Shadow', nameAr: 'الظل البنفسجي', priceCoins: 420),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_31', atlasIndex: 30, name: 'Opal Kingdom', nameAr: 'مملكة الأوبال', priceCoins: 520),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_32', atlasIndex: 31, name: 'Jungle Panther', nameAr: 'نمر الأدغال', priceCoins: 640),
    WorldVoiceFrameCatalogItem(id: 'frame__wv_frame_33', atlasIndex: 32, name: 'Pharaoh Gold', nameAr: 'ذهب الفراعنة', priceCoins: 590),
  ];

  static bool isFree(String? frameId) =>
      frameId != null &&
      (freeFrameIds.contains(frameId) || frameId == 'free_minimal_glow');

  static int? atlasIndex(String? frameId) {
    if (frameId == null || frameId.isEmpty) return null;
    for (final frame in bundledFrames) {
      if (frame.id == frameId) return frame.atlasIndex;
    }
    return null;
  }

  static bool isPremium(String? frameId) =>
      frameId?.startsWith('frame__') == true;

  static String label(String frameId, {required bool ar}) {
    for (final frame in bundledFrames) {
      if (frame.id == frameId) return ar ? frame.nameAr : frame.name;
    }
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
      WorldVoiceAvatarFrame.atlasIndex(widget.frameId) == null &&
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
    final assetIndex = WorldVoiceAvatarFrame.atlasIndex(id);
    if (assetIndex != null) {
      return SizedBox.square(
        dimension: widget.size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            SizedBox.square(
              dimension: widget.size * .66,
              child: ClipOval(child: widget.child),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: _BundledAvatarFrame(atlasIndex: assetIndex),
              ),
            ),
          ],
        ),
      );
    }
    if (id == null || id.trim().isEmpty) {
      return SizedBox.square(
        dimension: widget.size,
        child: ClipOval(child: widget.child),
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

/// The 33 transparent PNG source frames are packed into one 6x6 WebP texture.
/// Decoded once for the whole app; each avatar paints only its own cell.
class _BundledAvatarFrame extends StatelessWidget {
  const _BundledAvatarFrame({required this.atlasIndex});

  final int atlasIndex;
  static final Future<ui.Image> _image = _load();

  static Future<ui.Image> _load() async {
    final data = await rootBundle.load(
      'assets/frames/worldvoice_frames_atlas.webp',
    );
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ui.Image>(
        future: _image,
        builder: (context, snapshot) {
          final image = snapshot.data;
          if (image == null) return const SizedBox.expand();
          return CustomPaint(
            painter: _BundledFramePainter(
              image: image,
              atlasIndex: atlasIndex,
            ),
            child: const SizedBox.expand(),
          );
        },
      );
}

class _BundledFramePainter extends CustomPainter {
  const _BundledFramePainter({
    required this.image,
    required this.atlasIndex,
  });

  final ui.Image image;
  final int atlasIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    const columns = 6;
    final cellWidth = image.width / columns;
    final cellHeight = image.height / columns;
    final x = atlasIndex % columns;
    final y = atlasIndex ~/ columns;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(x * cellWidth, y * cellHeight, cellWidth, cellHeight),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _BundledFramePainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.atlasIndex != atlasIndex;
}
