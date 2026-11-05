import 'package:flutter/material.dart';
import 'world_bond_identity.dart';

/// Four shared platinum artworks, tinted to the selected relationship identity.
/// Gift level chooses only the shape; relationship type chooses the color.
class WorldBondGiftArt extends StatelessWidget {
  const WorldBondGiftArt({required this.level, this.size = 76,
    this.relationshipType = 'learning', super.key});
  final int level;
  final double size;
  final String relationshipType;

  @override
  Widget build(BuildContext context) {
    final tier = level.clamp(1, 4);
    final accent = WorldBondIdentity.accent(relationshipType);
    return RepaintBoundary(
      child: ShaderMask(
        blendMode: BlendMode.modulate,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [accent, Color.lerp(accent, Colors.white, .65)!, accent],
          stops: const [0, .45, 1],
        ).createShader(bounds),
        child: Image.asset('assets/world_bond/gift_0$tier.webp',
          width: size, height: size, fit: BoxFit.contain,
          cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
              .ceil().clamp(128, 1254).toInt(),
          filterQuality: FilterQuality.high,
          excludeFromSemantics: true,
          errorBuilder: (_, _, _) => SizedBox.square(dimension: size,
            child: const Icon(Icons.card_giftcard_rounded,
              color: Colors.white, size: 48)),
        ),
      ),
    );
  }
}
