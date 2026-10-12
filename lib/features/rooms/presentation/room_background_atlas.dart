import 'package:flutter/material.dart';

import '../data/room_background_catalog.dart';

/// Full-resolution portrait scene viewer. Each purchased scene has its own
/// optimized WebP asset; retired atlas artwork is never loaded.
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
  final bool fillUnderlay;

  @override
  Widget build(BuildContext context) {
    final path = RoomBackgroundCatalog.assetPathForTheme(themeId);
    if (path == null) {
      return const ColoredBox(color: Color(0xFF0D4A38));
    }
    return RepaintBoundary(
      child: Image.asset(
        path,
        fit: fit,
        filterQuality: filterQuality,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) =>
            const ColoredBox(color: Color(0xFF0D4A38)),
      ),
    );
  }
}
