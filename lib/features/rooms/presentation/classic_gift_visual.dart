import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/room_feature_models.dart';

/// Lightweight renderer for the approved 54-item WorldVoice gift pack.
///
/// All gift art is packed into one atlas which is decoded once and shared by
/// every grid tile / room overlay. This avoids loading dozens of full-size PNGs
/// while an Agora room is active.
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
  static const int _atlasPartCount = 9;
  static const int _atlasColumns = 9;
  static const int _atlasRows = 6;
  static final Future<ui.Image> _atlasImage = _loadAtlasImage();

  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1450),
  );

  static Future<ui.Image> _loadAtlasImage() async {
    final parts = await Future.wait(
      List.generate(_atlasPartCount, (index) {
        final suffix = index.toString().padLeft(2, '0');
        return rootBundle.loadString(
          'assets/gifts/catalog/atlas_$suffix.b64',
          cache: true,
        );
      }),
    );
    final bytes = base64Decode(parts.map((part) => part.trim()).join());
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  int? get _atlasIndex {
    final match = RegExp(r'^wv_gift_([0-9]{3})$').firstMatch(widget.gift.id);
    if (match == null) return null;
    final number = int.tryParse(match.group(1)!);
    if (number == null || number < 1 || number > 54) return null;
    return number - 1;
  }

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
        _motion.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  Widget _fallback() => Center(
        child: Text(
          widget.gift.emoji ?? '🎁',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: widget.size * .5),
        ),
      );

  Widget _art() {
    final atlasIndex = _atlasIndex;
    if (atlasIndex != null) {
      return FutureBuilder<ui.Image>(
        future: _atlasImage,
        builder: (context, snapshot) {
          final image = snapshot.data;
          if (image == null) return _fallback();
          return RepaintBoundary(
            child: CustomPaint(
              painter: _GiftAtlasPainter(
                image: image,
                index: atlasIndex,
                columns: _atlasColumns,
                rows: _atlasRows,
              ),
              child: const SizedBox.expand(),
            ),
          );
        },
      );
    }

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
    return _fallback();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _motion,
        builder: (context, child) {
          if (!widget.animate) return child!;

          final v = _motion.value;
          final wave = math.sin(v * math.pi * 2);
          final effect = widget.gift.effectType ?? '';
          final lift = const {
            'fly', 'float', 'glide', 'butterfly', 'phoenix', 'dragon',
          }.contains(effect);
          final energetic = const {
            'speed', 'burst', 'electric', 'flash', 'dragon', 'phoenix',
          }.contains(effect);
          final orbiting = const {
            'orbit', 'cosmic', 'spin',
          }.contains(effect);

          final dx = energetic ? wave * widget.size * .025 : 0.0;
          final dy = lift ? -widget.size * (.018 + .045 * v) : 0.0;
          final angle = orbiting ? wave * .035 : 0.0;
          final scale = 1 + (energetic ? .055 : .025) * v;

          return Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(widget.size * .035),
          child: _art(),
        ),
      ),
    );
  }
}

class _GiftAtlasPainter extends CustomPainter {
  const _GiftAtlasPainter({
    required this.image,
    required this.index,
    required this.columns,
    required this.rows,
  });

  final ui.Image image;
  final int index;
  final int columns;
  final int rows;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final cellWidth = image.width / columns;
    final cellHeight = image.height / rows;
    final column = index % columns;
    final row = index ~/ columns;
    final source = Rect.fromLTWH(
      column * cellWidth,
      row * cellHeight,
      cellWidth,
      cellHeight,
    );

    final fitted = applyBoxFit(BoxFit.contain, source.size, size);
    final sourceRect = Alignment.center.inscribe(fitted.source, source);
    final destination =
        Alignment.center.inscribe(fitted.destination, Offset.zero & size);

    canvas.drawImageRect(
      image,
      sourceRect,
      destination,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _GiftAtlasPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.index != index;
  }
}
