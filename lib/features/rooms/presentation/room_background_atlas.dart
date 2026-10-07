import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/room_background_catalog.dart';

/// Displays one of the 36 bundled WorldVoice room backgrounds.
///
/// The source artwork is stored as one 6x6 atlas split into base64 asset parts.
/// The parts are decoded once and reused by all previews and room backgrounds.
class RoomBackgroundAtlas extends StatelessWidget {
  const RoomBackgroundAtlas({
    required this.themeId,
    this.filterQuality = FilterQuality.medium,
    super.key,
  });

  final String themeId;
  final FilterQuality filterQuality;

  static const int _partCount = 80;
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
            if (!width.isFinite ||
                !height.isFinite ||
                width <= 0 ||
                height <= 0) {
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
