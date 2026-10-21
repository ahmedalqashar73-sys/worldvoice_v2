import 'package:flutter/material.dart';

/// Distinctive WorldVoice cosmetics; artwork is rendered without third-party
/// imagery. Store approval and prices always come from the backend catalog.
class WorldVoiceVipBadgeDesign {
  const WorldVoiceVipBadgeDesign({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.emoji,
    required this.colors,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String emoji;
  final List<Color> colors;

  static const designs = <WorldVoiceVipBadgeDesign>[
    WorldVoiceVipBadgeDesign(
      id: 'badge__moon_cat', nameAr: 'القطة القمرية',
      nameEn: 'Moon Cat', emoji: '🐈',
      colors: [Color(0xFFAFE4D1), Color(0xFF5CBF9C)],
    ),
    WorldVoiceVipBadgeDesign(
      id: 'badge__jade_heart', nameAr: 'قلب الزمرد',
      nameEn: 'Jade Heart', emoji: '💚',
      colors: [Color(0xFFB9EDDC), Color(0xFF57B7BC)],
    ),
    WorldVoiceVipBadgeDesign(
      id: 'badge__golden_puppy', nameAr: 'الجرو الذهبي',
      nameEn: 'Golden Puppy', emoji: '🐶',
      colors: [Color(0xFFFFEBC4), Color(0xFFF3BF63)],
    ),
    WorldVoiceVipBadgeDesign(
      id: 'badge__sakura', nameAr: 'زهرة الساكورا',
      nameEn: 'Sakura Bloom', emoji: '🌸',
      colors: [Color(0xFFFFDFEA), Color(0xFFF3A8C3)],
    ),
    WorldVoiceVipBadgeDesign(
      id: 'badge__mint_bear', nameAr: 'الدب النعناعي',
      nameEn: 'Mint Bear', emoji: '🐻',
      colors: [Color(0xFFD7F2DE), Color(0xFF89CEB6)],
    ),
    WorldVoiceVipBadgeDesign(
      id: 'badge__royal_crown', nameAr: 'التاج الملكي',
      nameEn: 'Royal Crown', emoji: '👑',
      colors: [Color(0xFFFFEFC9), Color(0xFFE4BE61)],
    ),
  ];

  static WorldVoiceVipBadgeDesign? byId(String? id) {
    for (final design in designs) {
      if (design.id == id) return design;
    }
    return null;
  }
}

/// Decoration shown next to a member's name only for valid server-issued
/// equipped badges with an active expiry.
class WorldVoiceVipBadge extends StatelessWidget {
  const WorldVoiceVipBadge({
    required this.badgeId,
    this.compact = true,
    super.key,
  });

  final String badgeId;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final design = WorldVoiceVipBadgeDesign.byId(badgeId);
    if (design == null) return const SizedBox.shrink();

    return Container(
      constraints: BoxConstraints(minWidth: compact ? 74 : 116),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 13,
        vertical: compact ? 4 : 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: design.colors),
        border: Border.all(color: const Color(0xFFD8AD55), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x1E1D6C55), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(design.emoji, style: TextStyle(fontSize: compact ? 16 : 28)),
          const SizedBox(width: 5),
          Text(
            'WV VIP',
            style: TextStyle(
              fontSize: compact ? 11 : 19,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF245044),
              letterSpacing: compact ? 0 : 1,
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 5),
            const Icon(Icons.stars_rounded, size: 17, color: Color(0xFF98671F)),
          ],
        ],
      ),
    );
  }
}
