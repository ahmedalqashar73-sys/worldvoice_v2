import 'package:flutter/material.dart';

import '../data/room_background_catalog.dart';

/// Crops one background out of the single bundled 6x6 WorldVoice atlas.
/// Keeping one decoded atlas avoids 36 separate asset decodes and keeps the
/// room background catalog compact.
class RoomBackgroundAtlas extends StatelessWidget {
  const RoomBackgroundAtlas({
    required this.themeId,
    this.filterQuality = FilterQuality.medium,
    super.key,
  });

  final String themeId;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    final index = RoomBackgroundCatalog.atlasIndexForTheme(themeId);
    if (index == null) return const SizedBox.expand();

    final column = index % RoomBackgroundCatalog.atlasColumns;
    final row = index ~/ RoomBackgroundCatalog.atlasColumns;

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
                child: Image.asset(
                  RoomBackgroundCatalog.atlasAssetPath,
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
  }
}
