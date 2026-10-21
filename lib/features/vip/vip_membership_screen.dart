import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/vip/vip_entitlement.dart';

/// Membership overview. No checkout button is shown until native subscription
/// products, receipt verification and restoration are ready for release.
class VipMembershipScreen extends StatelessWidget {
  const VipMembershipScreen({super.key, required this.languageCode});

  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final ar = languageCode == 'ar';
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'عضوية WorldVoice VIP' : 'WorldVoice VIP'),
      ),
      body: uid == null
          ? Center(child: Text(ar ? 'يرجى تسجيل الدخول.' : 'Please sign in.'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(ar
                        ? 'تعذر التحقق من حالة الاشتراك.'
                        : 'Could not load membership status.'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final profile = snapshot.data?.data();
                final active = VipEntitlement.isActive(profile);
                final expiresAt = VipEntitlement.expiryDate(profile)?.toLocal();
                final date = expiresAt == null
                    ? null
                    : '${expiresAt.year.toString().padLeft(4, '0')}-'
                        '${expiresAt.month.toString().padLeft(2, '0')}-'
                        '${expiresAt.day.toString().padLeft(2, '0')}';

                return ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Card(
                      color: const Color(0xFFF2F7EA),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          children: [
                            const Icon(Icons.workspace_premium_rounded,
                                color: Color(0xFFAA8125), size: 56),
                            const SizedBox(height: 12),
                            Text(
                              'WorldVoice VIP Gold',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              active
                                  ? (ar ? 'عضويتك فعّالة' : 'Your membership is active')
                                  : (ar ? 'لا توجد عضوية VIP فعّالة'
                                      : 'No active VIP membership'),
                              style: TextStyle(
                                color: active
                                    ? const Color(0xFF136D50)
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (date != null) ...[
                              const SizedBox(height: 8),
                              Text(ar ? 'تاريخ الانتهاء: $date'
                                  : 'Expiry date: $date'),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      ar ? 'مميزات VIP الحالية' : 'Current VIP benefits',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    _Benefit(
                      icon: Icons.timer_outlined,
                      title: ar ? 'وقت غير محدود' : 'Unlimited stage time',
                      subtitle: ar
                          ? 'داخل الغرف الصوتية واللايف كمضيف أو متحدث'
                          : 'Host or speak in voice rooms and Live without a time cap',
                    ),
                    _Benefit(
                      icon: Icons.smart_toy_outlined,
                      title: 'Teacher AI',
                      subtitle: ar
                          ? 'محادثة الذكاء الاصطناعي داخل الغرف الصوتية'
                          : 'Access to Teacher AI conversations in voice rooms',
                    ),
                    _Benefit(
                      icon: Icons.translate_rounded,
                      title: ar ? 'حتى 10 لغات تعلّم' : 'Up to 10 learning languages',
                      subtitle: ar
                          ? 'إضافة لغات تعلّم متعددة إلى ملفك'
                          : 'Track multiple learning languages on your profile',
                    ),
                    _Benefit(
                      icon: Icons.visibility_outlined,
                      title: ar ? 'قائمة زوار الملف الشخصي' : 'Profile visitors',
                      subtitle: ar
                          ? 'فتح قائمة من زار ملفك الشخصي'
                          : 'See the profile visitor list',
                    ),
                    _Benefit(
                      icon: Icons.visibility_off_outlined,
                      title: ar ? 'إخفاء سجل زياراتك' : 'Private profile visits',
                      subtitle: ar
                          ? 'اختيار إخفاء زياراتك من الإعدادات'
                          : 'Choose to hide your profile visits in Settings',
                    ),
                    const SizedBox(height: 18),
                    Text(
                      ar
                          ? 'الدفع والتجديد التلقائي عبر Google Play وApp Store غير متاحين بعد. سيتم عرض الاشتراكات بعد تفعيل منتجات المتجر والتحقق الآمن من المشتريات.'
                          : 'Subscriptions and auto-renewal through Google Play and the App Store are not available yet. Purchase options will appear after native products and secure receipt verification are enabled.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF127D63)),
          title: Text(title),
          subtitle: Text(subtitle),
        ),
      );
}
