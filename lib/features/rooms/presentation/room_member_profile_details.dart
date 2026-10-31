import 'package:flutter/material.dart';
import '../../profile/presentation/world_bond_screen.dart';
import '../../profile/data/profile_language_catalog.dart';
import '../../profile/presentation/member_badges.dart';

/// Public profile summary used on every room seat, including the host.
/// Only publicly exposed badge data is queried; wallet balances stay private.
class RoomMemberProfileDetails extends StatefulWidget {
  const RoomMemberProfileDetails({
    required this.userId,
    required this.profile,
    required this.isArabic,
    this.badgeLoader,
    super.key,
  });
  final String userId;
  final Map<String, dynamic> profile;
  final bool isArabic;
  final Future<Map<String, dynamic>> Function(String)? badgeLoader;

  @override
  State<RoomMemberProfileDetails> createState() =>
      _RoomMemberProfileDetailsState();
}

class _RoomMemberProfileDetailsState extends State<RoomMemberProfileDetails> {
  late Future<Map<String, dynamic>> _badge;
  static Future<Map<String, dynamic>> _loadBadge(String uid) async {
    final response = await WorldBondApi.request(
      'engagement/badges?userIds=${Uri.encodeQueryComponent(uid)}');
    final badges = response['badges'] as Map?;
    return Map<String, dynamic>.from(badges?[uid] as Map? ?? {});
  }

  @override
  void initState() {
    super.initState();
    _badge = (widget.badgeLoader ?? _loadBadge)(widget.userId);
  }

  @override
  void didUpdateWidget(covariant RoomMemberProfileDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _badge = (widget.badgeLoader ?? _loadBadge)(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final locale = widget.isArabic ? 'ar' : 'en';
    final native = ProfileLanguageCatalog.localizedStoredName(
      (p['nativeLanguageCode'] ?? p['nativeLanguage'])?.toString(), locale);
    final saved = (p['learningLanguageCodes'] as List?)?.isNotEmpty == true
        ? p['learningLanguageCodes'] as List
        : (p['learningLanguages'] as List?) ?? const <dynamic>[];
    final proficiency = p['learningLanguageLevels'] ?? p['languageLevels'];
    final learning = saved.map((value) {
      final entry = value is Map ? value : null;
      final code = entry == null ? value.toString()
        : (entry['code'] ?? entry['language'] ?? entry['name'] ?? '').toString();
      final name = ProfileLanguageCatalog.localizedStoredName(code, locale);
      final recorded = entry?['level'] ??
        (proficiency is Map ? proficiency[code] : null);
      return recorded == null || recorded.toString().trim().isEmpty
        ? name : '$name · $recorded';
    }).where((name) => name.isNotEmpty).toSet().toList(growable: false);
    final rawLevel = (p['languageLevel'] ?? '').toString().toLowerCase();
    final level = switch (rawLevel) {
      'beginner' => widget.isArabic ? 'مبتدئ' : 'Beginner',
      'intermediate' => widget.isArabic ? 'متوسط' : 'Intermediate',
      'advanced' => widget.isArabic ? 'متقدم' : 'Advanced',
      _ => rawLevel.toUpperCase(),
    };

    Widget infoChip(String label, IconData icon) => Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16, color: const Color(0xFFD2F6E4)),
      backgroundColor: const Color(0xFF174D3F),
      label: Text(label, style: const TextStyle(
          color: Colors.white, fontSize: 12)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: _badge,
          builder: (context, snapshot) {
            final vipBadge = snapshot.data?['vipBadge'] as String?;
            final giftLevel = (snapshot.data?['giftLevel'] as num?)?.toInt();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8, runSpacing: 5,
                children: [
                  if (vipBadge != null) VipSignatureBadge(design: vipBadge),
                  const Icon(Icons.diamond_rounded,
                    color: Color(0xFFFFD780), size: 20),
                  Text(
                    widget.isArabic ? 'مستوى الإهداء' : 'Gift level',
                    style: const TextStyle(
                      color: Color(0xFFF7E4B1), fontSize: 13,
                      fontWeight: FontWeight.bold),
                  ),
                  if (giftLevel != null)
                    GiftLevelBadge(level: giftLevel)
                  else
                    Text('—', style: TextStyle(
                      color: snapshot.hasError
                          ? Colors.orangeAccent : Colors.white70)),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 9),
        if (native.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            children: [
              infoChip(
                '${widget.isArabic ? 'اللغة الأم' : 'Native'}: $native',
                Icons.language_rounded),
            ],
          ),
        if (learning.isNotEmpty) ...[
          const SizedBox(height: 3),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 5, runSpacing: 2,
            children: [
              for (final lang in learning)
                infoChip(lang, Icons.translate_rounded),
            ],
          ),
        ],
        if (level.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${widget.isArabic ? 'مستوى التعلم' : 'Learning proficiency'}: $level',
              style: const TextStyle(color: Color(0xFFDAF7EB), fontSize: 12),
            ),
          ),
      ],
    );
  }
}
