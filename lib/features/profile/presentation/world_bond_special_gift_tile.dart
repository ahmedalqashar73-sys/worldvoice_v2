import 'package:flutter/material.dart';

import 'world_bond_gift_art.dart';

/// Premium, relationship-only gift. No room/Live catalog or wallet write here:
/// the WorldBond server endpoint confirms price and performs settlement.
class WorldBondSpecialGiftTile extends StatelessWidget {
  const WorldBondSpecialGiftTile({
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
      1 => const Color(0xFF49D6A2),
      2 => const Color(0xFF80DEEA),
      3 => const Color(0xFFC8A3F6),
      _ => const Color(0xFFFFD681),
    };
    final deepAccent = switch (level) {
      1 => const Color(0xFF195946),
      2 => const Color(0xFF1B5661),
      3 => const Color(0xFF453361),
      _ => const Color(0xFF66481E),
    };

    return Container(
      key: ValueKey('bond-premium-gift-tier-$level'),
      margin: const EdgeInsets.symmetric(vertical: 7),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [deepAccent, const Color(0xFF102F2B), deepAccent],
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: accent.withValues(alpha: .75)),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: .16),
            blurRadius: 14, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
        child: Row(
          children: [
            Semantics(
              label: isArabic ? 'هدية العلاقة الفئة $level' :
                  'Bond gift tier $level',
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withValues(alpha: .7)),
                ),
                child: WorldBondGiftArt(level: level, size: 79),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text(isArabic ? 'WorldBond • الفئة $level'
                      : 'WorldBond • Tier $level',
                    style: TextStyle(
                      color: accent, fontWeight: FontWeight.w700,
                      fontSize: 11)),
                  const SizedBox(height: 7),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on_rounded,
                        color: Color(0xFFFFD681), size: 17),
                      const SizedBox(width: 4),
                      Flexible(child: Text(
                        '$priceCoins ${isArabic ? 'كوين' : 'coins'}',
                        maxLines: 1,
                        style: const TextStyle(
                          color: Color(0xFFFFE8AD),
                          fontWeight: FontWeight.w900,
                          fontSize: 13),
                      )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            FilledButton(
              onPressed: canSend ? onSend : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D9A6C),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF304E46),
                disabledForegroundColor: Colors.white60,
                padding: const EdgeInsets.symmetric(
                  horizontal: 11, vertical: 11),
                minimumSize: const Size(58, 40),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(isArabic ? 'إهداء' : 'Send'),
            ),
          ],
        ),
      ),
    );
  }
}
