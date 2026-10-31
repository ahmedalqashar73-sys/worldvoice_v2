import 'package:flutter/material.dart';
import 'world_bond_gift_art.dart';

/// Four premium relationship-only gifts. These illustrations are Flutter
/// vectors, not room-gift assets, and the server is the coin-price authority.
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Semantics(
              label: isArabic ? 'هدية العلاقة المستوى $level' : 'Bond gift level $level',
              child: Column(children: [
                WorldBondGiftArt(level: level),
                Text('LV $level', style: const TextStyle(fontSize: 10,
                  color: Color(0xFF806017), fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 5),
                Text(
                  isArabic ? 'هدية WorldBond الخاصة' : 'WorldBond exclusive gift',
                  style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 3,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on_rounded,
                        color: Color(0xFFE8C468), size: 16),
                    Text('$priceCoins',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text(isArabic ? 'كوين' : 'coins',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            )),
            const SizedBox(width: 7),
            FilledButton(
              onPressed: canSend ? onSend : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF13885C),
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
