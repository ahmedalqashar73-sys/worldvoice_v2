import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/room_background_catalog.dart';

/// Crops one background out of the single bundled 6x6 WorldVoice atlas.
///
/// The atlas is stored as small base64 text parts so repository tooling can
/// keep the original user-provided artwork intact without runtime networking.
/// Parts are joined and decoded once, then the same bytes are reused by every
/// room seat/shop preview.
class RoomBackgroundAtlas extends StatelessWidget {
  const RoomBackgroundAtlas({
    required this.themeId,
    this.filterQuality = FilterQuality.medium,
    super.key,
  });

  final String themeId;
  final FilterQuality filterQuality;

  static const _partCount = 80;
  static final Future<Uint8List> _atlasBytes = _loadAtlasBytes();

  static Future<Uint8List> _loadAtlasBytes() async {
    final buffer = StringBuffer();
    for (var index = 0; index < _partCount; index++) {
      final suffix = index.toString().padLeft(2, '0');
      final part = await rootBundle.loadString(
        'assets/backgrounds/atlas_$suffix.b64',
        cache: true,
      );
      buffer.write(part.trim());
    }
    return base64Decode(buffer.toString());
  }

  @override
  Widget build(BuildContext context) {
    final index = RoomBackgroundCatalog.atlasIndexForTheme(themeId);
    if (index == null) return const SizedBox.expand();

    final column = index % RoomBackgroundCatalog.atlasColumns;
    final row = index ~/ RoomBackgroundCatalog.atlasColumns;

    return FutureBuilder<Uint8List>(
      future: _atlasBytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return const DecoratedBox(
            decoration: BoxDecoration(color: Color(0xFF102D25)),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            if (!width.isFinite || !height.isFinite ||
                width <= 0 || height <= 0) {
              return const SizedBox.shrink();
            }

            return ClipRect(
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: -column * width,
                    top: -row * height,
                    width: width * RoomBackgroundCatalog.atlasColumns,
                    height: height * RoomBackgroundCatalog.atlasRows,
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.fill,
                      filterQuality: filterQuality,
                      gaplessPlayback: true,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
