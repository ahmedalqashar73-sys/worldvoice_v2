import 'package:flutter/material.dart';

/// A relationship keeps its visual identity when its server level changes.
abstract final class WorldBondIdentity {
  static String normalize(String type) =>
      const ['learning', 'language', 'friend', 'duo'].contains(type)
          ? type : 'learning';

  static Color accent(String type) => switch (normalize(type)) {
    'language' => const Color(0xFF68DDF4),
    'friend' => const Color(0xFFC59BFF),
    'duo' => const Color(0xFFFFD17A),
    _ => const Color(0xFF42DFA7),
  };

  static Color background(String type) => switch (normalize(type)) {
    'language' => const Color(0xFF123C50),
    'friend' => const Color(0xFF35204F),
    'duo' => const Color(0xFF493519),
    _ => const Color(0xFF103E30),
  };

  static IconData icon(String type) => switch (normalize(type)) {
    'language' => Icons.forum_rounded,
    'friend' => Icons.handshake_rounded,
    'duo' => Icons.favorite_rounded,
    _ => Icons.menu_book_rounded,
  };

  static String badgeAsset(String type) =>
      'assets/world_bond/badge_${normalize(type)}.webp';
}

class WorldBondBadgeArt extends StatelessWidget {
  const WorldBondBadgeArt({required this.relationshipType,
    this.size = 40, super.key});
  final String relationshipType;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    WorldBondIdentity.badgeAsset(relationshipType),
    width: size, height: size, fit: BoxFit.contain,
    cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
        .ceil().clamp(64, 1254).toInt(),
    filterQuality: FilterQuality.high,
    excludeFromSemantics: true,
    errorBuilder: (_, _, _) => Icon(WorldBondIdentity.icon(relationshipType),
      size: size, color: WorldBondIdentity.accent(relationshipType)),
  );
}
