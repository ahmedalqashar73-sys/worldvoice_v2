import 'package:flutter/material.dart';
import 'world_bond_gift_art.dart';
import 'world_bond_identity.dart';
import 'world_bond_level_badge.dart';

/// An exclusive relationship gift in a room-store-style two-column gallery.
/// Sending is still verified and charged by the WorldBond backend.
class WorldBondGiftGalleryTile extends StatelessWidget {
  const WorldBondGiftGalleryTile({
    required this.level,
    this.relationshipType = 'learning',
    required this.name,
    required this.priceCoins,
    required this.isArabic,
    required this.canSend,
    required this.onSend,
    super.key,
  });

  final int level;
  final String relationshipType;
  final String name;
  final int priceCoins;
  final bool isArabic;
  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final accent = WorldBondIdentity.accent(relationshipType);
    final background = WorldBondIdentity.background(relationshipType);
    return Container(
      key: ValueKey('worldbond-gallery-gift-$level'),
      padding: const EdgeInsets.fromLTRB(7, 10, 7, 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [background, const Color(0xFF102B27), background],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: .83), width: 1.1),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: .15),
            blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: accent.withValues(alpha: .22), blurRadius: 15),
              ],
            ),
            child: WorldBondGiftArt(level: level, relationshipType: relationshipType, size: 94),
          ),
          const SizedBox(height: 6),
          Text(
            name, textAlign: TextAlign.center,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          WorldBondLevelBadge(level: level, relationshipType: relationshipType,
            compact: true, isArabic: isArabic),
          const SizedBox(height: 4),
          Text(
            '$priceCoins ${isArabic ? 'كوين' : 'coins'}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFFFE2A2),
              fontWeight: FontWeight.w900, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: ValueKey('worldbond-gallery-send-$level'),
              onPressed: canSend ? onSend : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D986D),
                disabledBackgroundColor: const Color(0xFF36574F),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white60,
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.redeem_rounded, size: 15),
              label: Text(isArabic ? 'إهداء' : 'Gift',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
