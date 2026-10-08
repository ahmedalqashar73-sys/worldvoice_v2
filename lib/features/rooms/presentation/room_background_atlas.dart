import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/room_background_catalog.dart';

/// Displays one of the 36 bundled WorldVoice room backgrounds.
///
/// The 6x6 atlas is decoded only once. Each widget paints only its own source
/// rectangle from the shared texture, avoiding the old 6x oversized Image
/// widget that made room/background-shop scrolling expensive.
class RoomBackgroundAtlas extends StatelessWidget {
  const RoomBackgroundAtlas({
    required this.themeId,
    this.filterQuality = FilterQuality.medium,
    this.fit = BoxFit.cover,
    this.fillUnderlay = false,
    super.key,
  });

  final String themeId;
  final FilterQuality filterQuality;
  final BoxFit fit;

  /// When [fit] is [BoxFit.contain], paint a dimmed cover layer underneath so
  /// the full artwork remains visible without empty bars around it.
  final bool fillUnderlay;

  static const int _partCount = 80;
  static final Future<ui.Image> _atlasImage = _loadAtlasImage();

  static Future<ui.Image> _loadAtlasImage() async {
    final parts = await Future.wait(
      List.generate(_partCount, (index) {
        final suffix = index.toString().padLeft(2, '0');
        return rootBundle.loadString(
          'assets/backgrounds/atlas_$suffix.b64',
          cache: true,
        );
      }),
    );

    final encoded = parts.map((part) => part.trim()).join();
    final bytes = base64Decode(encoded);
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = RoomBackgroundCatalog.atlasIndexForTheme(themeId);
    if (index == null) return const SizedBox.expand();

    // Render the original high-resolution Sunset Terrace artwork directly.
    // The 6x6 atlas is a compressed preview and loses detail on phone screens.
    if (themeId == 'wv_bg_18') {
      return RepaintBoundary(
        child: SizedBox.expand(
          child: Image.asset(
            'assets/backgrounds/sunset_terrace_hd.jpg',
            fit: fit,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: FutureBuilder<ui.Image>(
        future: _atlasImage,
        builder: (context, snapshot) {
          final image = snapshot.data;
          if (image == null) {
            return const DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFF102D25)),
            );
          }

          return CustomPaint(
            painter: _RoomBackgroundAtlasPainter(
              image: image,
              index: index,
              fit: fit,
              filterQuality: filterQuality,
              fillUnderlay: fillUnderlay,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _RoomBackgroundAtlasPainter extends CustomPainter {
  const _RoomBackgroundAtlasPainter({
    required this.image,
    required this.index,
    required this.fit,
    required this.filterQuality,
    required this.fillUnderlay,
  });

  final ui.Image image;
  final int index;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final bool fillUnderlay;

  Rect get _sourceCell {
    final cellWidth = image.width / RoomBackgroundCatalog.atlasColumns;
    final cellHeight = image.height / RoomBackgroundCatalog.atlasRows;
    final column = index % RoomBackgroundCatalog.atlasColumns;
    final row = index ~/ RoomBackgroundCatalog.atlasColumns;
    return Rect.fromLTWH(
      column * cellWidth,
      row * cellHeight,
      cellWidth,
      cellHeight,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..color = const Color(0xFF102D25));

    final source = _sourceCell;
    if (fillUnderlay && fit == BoxFit.contain) {
      _drawFitted(
        canvas,
        source,
        bounds,
        BoxFit.cover,
        opacity: .42,
      );
    }

    _drawFitted(
      canvas,
      source,
      bounds,
      fit,
      opacity: 1,
    );
  }

  void _drawFitted(
    Canvas canvas,
    Rect source,
    Rect destination,
    BoxFit boxFit, {
    required double opacity,
  }) {
    final fitted = applyBoxFit(boxFit, source.size, destination.size);
    final sourceRect = Alignment.center.inscribe(fitted.source, source);
    final destinationRect =
        Alignment.center.inscribe(fitted.destination, destination);

    final paint = Paint()
      ..filterQuality = filterQuality
      ..color = Colors.white.withValues(alpha: opacity);

    canvas.drawImageRect(
      image,
      sourceRect,
      destinationRect,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RoomBackgroundAtlasPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.index != index ||
        oldDelegate.fit != fit ||
        oldDelegate.filterQuality != filterQuality ||
        oldDelegate.fillUnderlay != fillUnderlay;
  }
}
