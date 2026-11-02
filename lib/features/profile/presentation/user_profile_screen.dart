import 'world_bond_screen.dart';
import 'gift_wall_screen.dart';
import 'profile_photo_viewer.dart';
import 'member_badges.dart';
import '../../engagement/presentation/creative_progress_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/services/auth_service.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/widgets/worldvoice_avatar_frame.dart';
import '../services/profile_social_service.dart';
import '../data/profile_language_catalog.dart';
import 'profile_connections_screen.dart';
import '../../rooms/presentation/room_background_shop_sheet.dart';
import '../../rooms/presentation/gift_coin_amount.dart';
import 'profile_identity_strip.dart';
import 'profile_setup_screen.dart';
import 'profile_visitors_screen.dart';
import 'settings_screen.dart';
import 'vip_membership_screen.dart';
import 'voice_bio_card.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({required this.localeController, super.key});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final code =
        localeController.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    final rtl = const {'ar', 'ur', 'fa'}.contains(code);

    if (uid == null) {
      return const Scaffold(body: Center(child: Text('No signed-in user')));
    }

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            code == 'ar'
                ? 'بروفايلي'
                : code == 'es'
                ? 'Mi perfil'
                : 'My profile',
          ),
          actions: [
            IconButton(
              tooltip: code == 'ar'
                  ? 'الخلفيات والإطارات والفقاعات'
                  : 'WorldVoice Appearance Shop',
              icon: const Icon(Icons.storefront_rounded),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => RoomBackgroundShopSheet(),
              ),
            ),
            IconButton(
              key: const ValueKey('profile-vip-store'),
              tooltip: code == 'ar' ? 'متجر VIP' : 'VIP membership',
              icon: const Icon(Icons.workspace_premium_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const VipMembershipScreen(),
                ),
              ),
            ),
            IconButton(
              tooltip: AppStrings.of(code).profile('settings'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        SettingsScreen(localeController: localeController),
                  ),
                );
              },
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() ?? const <String, dynamic>{};
            final name = (data['displayName'] as String?)?.trim();
            final username = (data['username'] as String?)?.trim();
            final bio = (data['bio'] as String?)?.trim();
            final photo = data['photoUrl'] as String?;
            final cover = data['coverUrl'] as String?;
            final country = data['country'] as String?;
            final gender = data['gender'] as String?;
            final nativeLanguage = ProfileLanguageCatalog.localizedStoredName(
              (data['nativeLanguageCode'] ?? data['nativeLanguage'])
                  ?.toString(),
              code,
            );
            final birthRaw = data['birthDate'];
            final birthDate = birthRaw is Timestamp ? birthRaw.toDate() : null;
            final isVip = data['isVip'] == true;
            final profileFrameId = (data['profileFrameId'] as String?)?.trim();
            final voiceBioUrl = data['voiceBioUrl'] as String?;
            final savedLearning =
                (data['learningLanguageCodes'] as List?)?.isNotEmpty == true
                ? (data['learningLanguageCodes'] as List)
                : (data['learningLanguages'] as List?) ?? const [];
            final learning = savedLearning
                .map(
                  (e) => ProfileLanguageCatalog.localizedStoredName(
                    e.toString(),
                    code,
                  ),
                )
                .toList();
            final hobbies =
                (data['interests'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                const <String>[];

            return ListView(
              padding: const EdgeInsets.only(bottom: 30),
              children: [
                SizedBox(
                  height: 224,
                  child: Stack(
                    children: [
                      GestureDetector(
                        key: const ValueKey('profile-cover-viewer-trigger'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ProfilePhotoViewer(
                              userId: uid, cover: true),
                          ),
                        ),
                        child: Container(
                          height: 170,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D6B4F), Color(0xFF5F47C8)],
                            ),
                            image: cover == null || cover.isEmpty
                                ? null
                                : DecorationImage(
                                    image: NetworkImage(cover),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        start: 22,
                        bottom: 4,
                        child: GestureDetector(
                          key: const ValueKey('profile-avatar-viewer-trigger'),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ProfilePhotoViewer(userId: uid),
                            ),
                          ),
                          child: WorldVoiceAvatarFrame(
                            frameId: profileFrameId,
                            size: 112,
                          child: ColoredBox(
                            color: Theme.of(context).colorScheme.surface,
                            child: photo == null || photo.isEmpty
                                ? const Center(
                                    child: Icon(Icons.person_rounded, size: 58),
                                  )
                                : Image.network(
                                    photo,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Center(
                                      child: Icon(
                                        Icons.person_rounded,
                                        size: 58,
                                      ),
                                    ),
                                  ),
                          ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MemberName(
                        userId: uid,
                        name: name?.isNotEmpty == true ? name! : 'WorldVoice',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${username?.isNotEmpty == true ? username! : 'user'}',
                      ),
                      ProfileIdentityStrip(
                        code: code,
                        country: country,
                        gender: gender,
                        birthDate: birthDate,
                        nativeLanguage: nativeLanguage,
                      ),
                      if (bio?.isNotEmpty == true) ...[
                        const SizedBox(height: 14),
                        Text(bio!),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _LiveCountStat(
                            stream: ProfileSocialService.followers(uid),
                            label: AppStrings.of(code).profile('followers'),
                            onTap: () => _openConnections(
                              context,
                              ProfileConnectionType.followers,
                            ),
                          ),
                          _LiveCountStat(
                            stream: ProfileSocialService.following(uid),
                            label: AppStrings.of(code).profile('following'),
                            onTap: () => _openConnections(
                              context,
                              ProfileConnectionType.following,
                            ),
                          ),
                          _StaticStat(
                            value: isVip ? 'VIP' : 'Free',
                            label: AppStrings.of(code).profile('plan'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProfileSetupScreen(
                                  localeController: localeController,
                                  editMode: true,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(
                            AppStrings.of(code).profile('editProfile'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _ProfileAction(
                              icon: Icons.handshake_outlined,
                              title: 'Partner',
                              onTap: () => _openConnections(
                                context,
                                ProfileConnectionType.partners,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ProfileAction(
                              icon: Icons.visibility_outlined,
                              title: AppStrings.of(code).profile('visitors'),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProfileVisitorsScreen(
                                      localeController: localeController,
                                      isVip: isVip,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0A8058),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const WorldBondScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.diversity_2_rounded),
                          label: Text(code == 'ar'
                              ? 'WorldBond • دعواتي ورغباتي'
                              : 'WorldBond • My invitations & wishlist'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          key: const ValueKey('profile-gift-wall'),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => GiftWallScreen(
                                profileUid: uid,
                                profileName: (data['displayName'] ?? 'WorldVoice').toString(),
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.card_giftcard_rounded),
                          label: Text(code == 'ar'
                              ? 'حائط الهدايا • المستلمة للجميع والمرسلة خاصة'
                              : 'Gift wall • public received, private sent'),
                        ),
                      ),
                      CreativeProfileLink(userId: uid),
                      const SizedBox(height: 12),
                      VoiceBioCard(
                        userId: uid,
                        code: code,
                        existingUrl: voiceBioUrl,
                      ),
                      _InfoCard(
                        icon: Icons.translate_rounded,
                        title: ProfileLanguageCatalog.localizedFieldTitle(
                          'learning',
                          code,
                        ),
                        value: learning.isEmpty ? '—' : learning.join(' • '),
                        trailing: IconButton.filledTonal(
                          tooltip: profileAddLearningLabel(code),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProfileSetupScreen(
                                  localeController: localeController,
                                  editMode: true,
                                  openLearningPickerOnLaunch: true,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ),
                      _InfoCard(
                        icon: Icons.favorite_outline_rounded,
                        title: AppStrings.of(code).profile('interests'),
                        value: hobbies.isEmpty ? '—' : hobbies.join(' • '),
                      ),
                      _InfoCard(
                        icon: Icons.work_outline_rounded,
                        title: AppStrings.of(code).profile('profession'),
                        value: (data['profession'] ?? '—').toString(),
                      ),
                      const SizedBox(height: 8),
                      // Monetary balances must be read only from the
                      // authenticated user's private wallet, never from the
                      // legacy public users/{uid} profile fields.
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        key: const ValueKey('profile-private-wallet-balances'),
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('private')
                            .doc('wallet')
                            .snapshots(),
                        builder: (context, walletSnapshot) {
                          final wallet = walletSnapshot.data?.data();
                          final walletAvailable =
                              !walletSnapshot.hasError &&
                              walletSnapshot.data?.exists == true;
                          String balance(String field) {
                            final value = wallet?[field];
                            return walletAvailable && value is num
                                ? value.toInt().toString()
                                : '—';
                          }

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _Wallet(
                                      icon: Icons.diamond_outlined,
                                      value: balance('diamonds'),
                                      label: AppStrings.of(code).profile(
                                        'diamonds',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _Wallet(
                                      icon: Icons.monetization_on_outlined,
                                      worldVoiceCoin: true,
                                      value: balance('coins'),
                                      label: AppStrings.of(code).profile(
                                        'coins',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (!walletAvailable &&
                                  walletSnapshot.connectionState !=
                                      ConnectionState.waiting)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    code == 'ar'
                                        ? 'تعذر تحميل المحفظة الخاصة. تحقق من تهيئتها وصلاحيات Firebase.'
                                        : 'Private wallet unavailable. Check setup and Firebase permissions.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      if (data['isAdmin'] == true)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextButton.icon(
                            key: const ValueKey('owner-monthly-coin-sync'),
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(code == 'ar'
                                ? 'تحديث مكافأة المالك الشهرية'
                                : 'Refresh monthly owner coins'),
                            onPressed: () async {
                              String message;
                              Map<String, dynamic>? diagnostics;
                              try {
                                final result =
                                    await AuthService.syncOwnerMonthlyCoinsNow();
                                final credited =
                                    (result['creditedCoins'] as num?)?.toInt() ?? 0;
                                if (result['privileged'] != true) {
                                  message = code == 'ar'
                                      ? 'حساب Google الحالي لم يجتز تحقق المالك على الخادم.'
                                      : 'This Google account did not pass server owner verification.';
                                } else if (credited > 0) {
                                  message = code == 'ar'
                                      ? 'أُضيف $credited كوينز إلى محفظتك الخاصة.'
                                      : '$credited coins credited to your private wallet.';
                                } else if (result['alreadyCredited'] == true) {
                                  message = code == 'ar'
                                      ? 'تم صرف مكافأة هذا الشهر مسبقًا.'
                                      : 'This month\'s owner reward was already credited.';
                                } else {
                                  message = code == 'ar'
                                      ? 'اكتملت المزامنة دون إضافة رصيد جديد.'
                                      : 'Sync completed without new coins.';
                                }
                              } catch (error) {
                                message = code == 'ar'
                                    ? 'فشلت مزامنة مكافأة المالك: $error'
                                    : 'Owner reward sync failed: $error';
                              }
                              try {
                                diagnostics = await AuthService.ownerReadinessNow();
                              } catch (error) {
                                message = '$message\n$error';
                              }
                              if (!context.mounted) return;
                              final details = diagnostics;
                              final ar = code == 'ar';
                              String flag(bool value) => value
                                  ? (ar ? 'نعم' : 'Yes')
                                  : (ar ? 'لا' : 'No');
                              final diagnosticText = details == null
                                  ? ''
                                  : [
                                      '${ar ? 'البريد يطابق حساب المالك' : 'Owner email matches'}: ${flag(details['signedInOwnerEmailMatched'] == true)}',
                                      '${ar ? 'معرّف تسجيل الدخول يطابق سجل المالك' : 'Firebase owner UID matches'}: ${flag(details['signedInUidMatchesOwnerRecord'] == true)}',
                                      '${ar ? 'تسجيل الدخول الحالي بواسطة Google' : 'Google sign-in used'}: ${flag(details['signedInWithGoogle'] == true)}',
                                      '${ar ? 'Google مرتبط بحسابك الحالي' : 'Google linked to signed-in account'}: ${flag(details['signedInGoogleProviderLinked'] == true)}',
                                      '${ar ? 'Google مرتبط بسجل المالك القديم' : 'Google linked to owner record'}: ${flag(details['ownerEmailRecordGoogleLinked'] == true)}',
                                      '${ar ? 'حساب المالك موثّق في Firebase' : 'Firebase owner email verified'}: ${flag(details['ownerEmailRecordVerified'] == true)}',
                                      '${ar ? 'بريد Google موثّق في الجلسة' : 'Signed-in email verified'}: ${flag(details['emailVerified'] == true)}',
                                      '${ar ? 'صلاحيات المالك موقّعة' : 'Signed owner claims'}: ${flag(details['signedClaimsComplete'] == true)}',
                                      '${ar ? 'سجل الإدارة المحمي مطابق' : 'Trusted admin record'}: ${flag(details['serverOwnedAdminRecordMatched'] == true)}',
                                      '${ar ? 'البريد معتمد للمالك' : 'Owner email allowlisted'}: ${flag(details['ownerAllowlistMatched'] == true)}',
                                      '${ar ? 'المحفظة الخاصة موجودة' : 'Private wallet exists'}: ${flag(details['privateWalletExists'] == true)}',
                                      '${ar ? 'الاقتصاد مفعّل' : 'Economy enabled'}: ${flag(details['economyEnabled'] == true)}',
                                      '${ar ? 'الانتقال للمحفظة معتمد' : 'Wallet cutover approved'}: ${flag(details['privateWalletCutoverVerified'] == true)}',
                                      '${ar ? 'صلاحيات الملف العام معتمدة' : 'Profile rules approved'}: ${flag(details['publicProfileRulesVerified'] == true)}',
                                    ].join('\n');
                              await showDialog<void>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text(ar
                                      ? 'حالة مكافأة المالك والمحفظة'
                                      : 'Owner coin and wallet status'),
                                  content: SingleChildScrollView(
                                    child: Text(diagnosticText.isEmpty
                                        ? message
                                        : '$message\n\n$diagnosticText'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(),
                                      child: Text(ar ? 'إغلاق' : 'Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      if (data['isAdmin'] == true)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextButton.icon(
                            key: const ValueKey('owner-verify-google-proof'),
                            icon: const Icon(Icons.verified_user_outlined),
                            label: Text(code == 'ar'
                                ? 'إثبات ملكية حساب المالك عبر Google'
                                : 'Verify owner identity with Google'),
                            onPressed: () async {
                              String message;
                              try {
                                final verification =
                                    await AuthService.verifyOwnerWithGoogleNow();
                                final result =
                                    await AuthService.syncOwnerMonthlyCoinsNow();
                                final credited =
                                    (result['creditedCoins'] as num?)?.toInt() ?? 0;
                                message = code == 'ar'
                                    ? credited > 0
                                        ? 'تم توثيق حسابك وإضافة $credited كوينز لهذا الشهر.'
                                        : result['alreadyCredited'] == true
                                            ? 'تم توثيق حسابك؛ مكافأة الشهر مصروفة مسبقًا.'
                                            : 'تم توثيق حسابك. تحقق من حالة المحفظة.'
                                    : credited > 0
                                        ? 'Owner verified; $credited monthly coins credited.'
                                        : result['alreadyCredited'] == true
                                            ? 'Owner verified; monthly grant was already credited.'
                                            : 'Owner verified. Check wallet readiness.';
                                if (verification['googleLinked'] != true) {
                                  message += code == 'ar'
                                      ? '\nتنبيه: تم إثبات البريد، لكن ربط Google بهذا الحساب لم يكتمل. لن ننقل أي حساب آخر تلقائيًا.'
                                      : '\nNote: Email verified, but Google linking did not complete. No other account was migrated.';
                                }
                              } catch (error) {
                                message = code == 'ar'
                                    ? 'تعذر إثبات حساب المالك أو صرف المكافأة: $error'
                                    : 'Owner verification or reward failed: $error';
                              }
                              if (!context.mounted) return;
                              await showDialog<void>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text(code == 'ar'
                                      ? 'نتيجة إثبات حساب المالك'
                                      : 'Owner verification result'),
                                  content: Text(message),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(),
                                      child: Text(code == 'ar' ? 'إغلاق' : 'Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openConnections(BuildContext context, ProfileConnectionType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileConnectionsScreen(
          type: type,
          localeController: localeController,
        ),
      ),
    );
  }
}

class _LiveCountStat extends StatelessWidget {
  const _LiveCountStat({
    required this.stream,
    required this.label,
    required this.onTap,
  });

  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StaticStat extends StatelessWidget {
  const _StaticStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
      ),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.all(14),
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(value),
      trailing: trailing,
    ),
  );
}

class _Wallet extends StatelessWidget {
  const _Wallet({required this.icon, required this.value, required this.label,
    this.worldVoiceCoin = false});

  final IconData icon;
  final bool worldVoiceCoin;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          worldVoiceCoin
              ? const WorldVoiceCoinIcon(size: 27)
              : Icon(icon),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          Text(label),
        ],
      ),
    ),
  );
}
