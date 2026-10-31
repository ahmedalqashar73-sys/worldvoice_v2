import 'package:flutter/material.dart';

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

  static const _gradients = <List<Color>>[
    [Color(0xFF064D43), Color(0xFF22B889), Color(0xFFAEF5CD)],
    [Color(0xFF63410E), Color(0xFFD3A646), Color(0xFFFFE1A2)],
    [Color(0xFF322A78), Color(0xFF8674DE), Color(0xFFCAE7FF)],
    [Color(0xFF5D2446), Color(0xFFB46B9E), Color(0xFFFFE4AD)],
  ];
  static const _icons = <IconData>[
    Icons.spa_rounded,
    Icons.hub_rounded,
    Icons.diamond_rounded,
    Icons.workspace_premium_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final index = (level - 1).clamp(0, 3).toInt();
    final gradient = _gradients[index];
    final primary = gradient[1];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Semantics(
              label: isArabic ? 'هدية العلاقة المستوى $level' : 'Bond gift level $level',
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: .22),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 57, height: 57,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xAA071F1B),
                        border: Border.all(color: const Color(0xE6FFE6B2), width: 2),
                      ),
                    ),
                    Icon(_icons[index], color: const Color(0xFFFFEFC7), size: 36),
                    Positioned(
                      bottom: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10251F),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'LV $level',
                          style: const TextStyle(
                            color: Color(0xFFFFE9AB), fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded,
                        color: Color(0xFFE8C468), size: 16),
                    const SizedBox(width: 4),
                    Text('$priceCoins',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(width: 3),
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
