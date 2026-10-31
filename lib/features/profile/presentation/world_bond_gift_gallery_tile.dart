import 'package:flutter/material.dart';
import 'world_bond_gift_art.dart';

/// An exclusive relationship gift in a room-store-style two-column gallery.
/// Sending is still verified and charged by the WorldBond backend.
class WorldBondGiftGalleryTile extends StatelessWidget {
  const WorldBondGiftGalleryTile({
    required this.level,
    required this.name,
    required this.priceCoins,
    required this.isArabic,
    required this.canSend,
    required this.onSend,
    super.key,
  });

  final int level;
  final String name;
  final int priceCoins;
  final bool isArabic;
  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final accent = switch (level) {
      1 => const Color(0xFF2FD6A0),
      2 => const Color(0xFF6CDAF5),
      3 => const Color(0xFFC6A2FF),
      _ => const Color(0xFFFFD17A),
    };
    final background = switch (level) {
      1 => const Color(0xFF114E3D),
      2 => const Color(0xFF17495A),
      3 => const Color(0xFF403060),
      _ => const Color(0xFF5D431C),
    };
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
            child: WorldBondGiftArt(level: level, size: 94),
          ),
          const SizedBox(height: 6),
          Text(
            name, textAlign: TextAlign.center,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            'LV$level',
            style: TextStyle(
              color: accent, fontSize: 11, fontWeight: FontWeight.w900),
          ),
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
