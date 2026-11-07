import 'package:flutter/material.dart';
import 'world_bond_identity.dart';

/// One emblem per relationship; the server level is text beside the emblem.
class WorldBondLevelBadge extends StatelessWidget {
  const WorldBondLevelBadge({required this.level,
    this.relationshipType = 'learning', this.compact = false,
    this.isArabic = true, this.chat = false, super.key});
  final int level;
  final String relationshipType;
  final bool compact;
  final bool chat;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final value = level.clamp(1, 5);
    final accent = WorldBondIdentity.accent(relationshipType);
    final relationshipName = switch (relationshipType) {
      'language' => isArabic ? 'رفيق اللغة' : 'Language partner',
      'friend' => isArabic ? 'صديق مميز' : 'Special friend',
      'duo' => isArabic ? 'ثنائي' : 'Duo',
      _ => isArabic ? 'رفيق التعلم' : 'Learning partner',
    };
    return Semantics(
      label: isArabic ? 'شارة العلاقة المستوى $value'
          : 'WorldBond badge level $value',
      child: Container(
        key: ValueKey('worldbond-level-badge-$value'),
        padding: EdgeInsets.symmetric(horizontal: chat ? 4 : (compact ? 5 : 9), vertical: chat ? 1 : 2),
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
            size: chat ? 18 : (compact ? 26 : 38)),
          SizedBox(width: chat ? 2 : 4),
          Text(chat ? relationshipName : 'Level $value',
            textDirection: chat && isArabic ? TextDirection.rtl : TextDirection.ltr,
            style: TextStyle(color: accent, fontSize: chat ? 9 : (compact ? 10 : 12),
              fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}
