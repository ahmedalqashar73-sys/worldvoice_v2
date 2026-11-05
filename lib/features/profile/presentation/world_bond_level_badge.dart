import 'package:flutter/material.dart';
import 'world_bond_identity.dart';

/// One emblem per relationship; the server level is text beside the emblem.
class WorldBondLevelBadge extends StatelessWidget {
  const WorldBondLevelBadge({required this.level,
    this.relationshipType = 'learning', this.compact = false,
    this.isArabic = true, super.key});
  final int level;
  final String relationshipType;
  final bool compact;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final value = level.clamp(1, 5);
    final accent = WorldBondIdentity.accent(relationshipType);
    return Semantics(
      label: isArabic ? 'شارة العلاقة المستوى $value'
          : 'WorldBond badge level $value',
      child: Container(
        key: ValueKey('worldbond-level-badge-$value'),
        padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 9, vertical: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            WorldBondIdentity.background(relationshipType),
            const Color(0xFF111C20),
          ]),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: accent.withValues(alpha: .65)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          WorldBondBadgeArt(relationshipType: relationshipType,
            size: compact ? 26 : 38),
          const SizedBox(width: 4),
          Text('Level $value', textDirection: TextDirection.ltr,
            style: TextStyle(color: accent, fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}
