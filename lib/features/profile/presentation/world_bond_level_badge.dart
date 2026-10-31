import 'package:flutter/material.dart';

/// Visual-only WorldBond relationship badge. Server remains authoritative
/// for level and XP; the four paid gift tiers are a separate system.
class WorldBondLevelBadge extends StatelessWidget {
  const WorldBondLevelBadge({
    required this.level,
    this.compact = false,
    this.isArabic = true,
    super.key,
  });

  final int level;
  final bool compact;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final value = level.clamp(1, 5);
    final colors = switch (value) {
      1 => const [Color(0xFF136E58), Color(0xFF34D4A1)],
      2 => const [Color(0xFF127D9B), Color(0xFF74E9F4)],
      3 => const [Color(0xFF6635A6), Color(0xFFC49EFF)],
      4 => const [Color(0xFF996021), Color(0xFFFFDA83)],
      _ => const [Color(0xFF137F71), Color(0xFFD5A74C)],
    };
    final name = isArabic
        ? switch (value) {
            1 => 'زمرد',
            2 => 'سماوي',
            3 => 'بنفسجي',
            4 => 'ذهبي',
            _ => 'ملكي',
          }
        : switch (value) {
            1 => 'Emerald',
            2 => 'Azure',
            3 => 'Amethyst',
            4 => 'Gold',
            _ => 'Royal',
          };

    return Semantics(
      label: isArabic ? 'شارة رابطة $name المستوى $value'
          : '$name WorldBond badge level $value',
      child: Container(
        key: ValueKey('worldbond-level-badge-$value'),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 10,
          vertical: compact ? 4 : 7,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: const Color(0xFFFFE7AB),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: .25),
              blurRadius: 9,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              switch (value) {
                1 => Icons.spa_rounded,
                2 => Icons.water_drop_rounded,
                3 => Icons.auto_awesome_rounded,
                4 => Icons.workspace_premium_rounded,
                _ => Icons.crown,
              },
              size: compact ? 13 : 17,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              compact ? 'LV$value' : '$name · LV$value',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w900,
                shadows: const [
                  Shadow(color: Color(0x99000000), blurRadius: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
