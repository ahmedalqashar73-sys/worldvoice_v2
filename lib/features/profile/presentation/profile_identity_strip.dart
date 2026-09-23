import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../data/profile_identity_utils.dart';

class ProfileIdentityStrip extends StatelessWidget {
  const ProfileIdentityStrip({
    required this.code,
    this.country,
    this.gender,
    this.birthDate,
    this.nativeLanguage,
    super.key,
  });

  final String code;
  final String? country;
  final String? gender;
  final DateTime? birthDate;
  final String? nativeLanguage;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(code);
    final age = profileAge(birthDate);
    final genderLabel = profileGenderLabel(gender, strings);
    final items = <Widget>[];

    if (country?.isNotEmpty == true) {
      items.add(
        _IdentityChip(
          leadingText: profileCountryFlag(country),
          text: country!,
        ),
      );
    }

    if (age != null) {
      items.add(
        _IdentityChip(
          icon: Icons.cake_outlined,
          text: strings.profileAge(age),
        ),
      );
    }

    if (genderLabel != null) {
      final isFemale = gender == 'female';
      items.add(
        _IdentityChip(
          icon: isFemale
              ? Icons.female_rounded
              : Icons.male_rounded,
          text: genderLabel,
          backgroundColor: isFemale
              ? const Color(0xFFFF4F9A).withValues(alpha: .16)
              : const Color(0xFF27B9F3).withValues(alpha: .16),
          foregroundColor: isFemale
              ? const Color(0xFFFF4F9A)
              : const Color(0xFF149FE0),
        ),
      );
    }

    if (nativeLanguage?.isNotEmpty == true) {
      items.add(
        _IdentityChip(
          icon: Icons.translate_rounded,
          text: nativeLanguage!,
        ),
      );
    }

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

class _IdentityChip extends StatelessWidget {
  const _IdentityChip({
    required this.text,
    this.icon,
    this.leadingText,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String text;
  final IconData? icon;
  final String? leadingText;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor ??
            colors.surfaceContainerHighest.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingText != null) ...[
            Text(leadingText!, style: const TextStyle(fontSize: 17)),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(
              icon,
              size: 17,
              color: foregroundColor ?? colors.primary,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
