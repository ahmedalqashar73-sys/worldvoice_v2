import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final match = RegExp(r'^wv_bg_(\\d{2})
    if (index == null) return const SizedBox.expand();

    final column = index % 6;
    final row = index ~/ 6;

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
                    width: width * 6,
                    height: height * 6,
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
).firstMatch(themeId);
    final number = int.tryParse(match?.group(1) ?? '');
    final index =
        number != null && number >= 1 && number <= 36 ? number - 1 : null;
    if (index == null) return const SizedBox.expand();

    final column = index % 6;
    final row = index ~/ 6;

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
                    width: width * 6,
                    height: height * 6,
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
