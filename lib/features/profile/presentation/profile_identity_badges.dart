import 'package:flutter/material.dart';

import '../data/profile_identity_utils.dart';

class ProfileIdentityBadges extends StatelessWidget {
  const ProfileIdentityBadges({
    required this.data,
    required this.code,
    super.key,
  });

  final Map<String, dynamic> data;
  final String code;

  @override
  Widget build(BuildContext context) {
    final country = (data['country'] as String?)?.trim();
    final gender = data['gender'] as String?;
    final age = profileAge(data['birthDate']);
    final nativeCode = (data['nativeLanguageCode'] as String?)?.trim();
    final nativeName = (data['nativeLanguage'] as String?)?.trim();
    final genderLabel = profileGenderLabel(gender, code);

    final items = <Widget>[
      if (country?.isNotEmpty == true)
        _IdentityPill(
          iconText: profileCountryFlag(country),
          label: country!,
        ),
      if (age != null)
        _IdentityPill(
          icon: Icons.cake_outlined,
          label: age.toString(),
        ),
      if (genderLabel != null)
        _IdentityPill(
          icon: gender == 'female'
              ? Icons.female_rounded
              : Icons.male_rounded,
          label: genderLabel,
        ),
      if (nativeCode?.isNotEmpty == true || nativeName?.isNotEmpty == true)
        _IdentityPill(
          icon: Icons.translate_rounded,
          label: [
            if (nativeCode?.isNotEmpty == true) nativeCode!.toUpperCase(),
            if (nativeName?.isNotEmpty == true) nativeName!,
          ].join(' • '),
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items,
      ),
    );
  }
}

class _IdentityPill extends StatelessWidget {
  const _IdentityPill({
    required this.label,
    this.icon,
    this.iconText,
  });

  final String label;
  final IconData? icon;
  final String? iconText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: .45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconText != null) ...[
            Text(iconText!, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 17),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
