import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Product identifiers must be created in Google Play Console and App Store
/// Connect. Querying a product is read-only; this screen NEVER starts billing
/// or writes VIP entitlements from the client.
abstract final class VipStoreConfiguration {
  static const androidMonthlyProductId =
      String.fromEnvironment('WORLDVOICE_VIP_ANDROID_MONTHLY_ID');
  static const iosMonthlyProductId =
      String.fromEnvironment('WORLDVOICE_VIP_IOS_MONTHLY_ID');

  static String? get monthlyProductId {
    if (kIsWeb) return null;
    final id = switch (defaultTargetPlatform) {
      TargetPlatform.android => androidMonthlyProductId,
      TargetPlatform.iOS => iosMonthlyProductId,
      _ => '',
    };
    return id.trim().isEmpty ? null : id.trim();
  }
}

class VipMembershipScreen extends StatefulWidget {
  const VipMembershipScreen({super.key});

  @override
  State<VipMembershipScreen> createState() => _VipMembershipScreenState();
}

class _VipMembershipScreenState extends State<VipMembershipScreen> {
  static const _green = Color(0xFF145A43);

  late final Future<ProductDetails?> _monthlyProduct;

  bool get _arabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _monthlyProduct = _getMonthlyProduct();
  }

  Future<ProductDetails?> _getMonthlyProduct() async {
    final productId = VipStoreConfiguration.monthlyProductId;
    if (productId == null) return null;
    try {
      final store = InAppPurchase.instance;
      if (!await store.isAvailable()) return null;
      final response = await store.queryProductDetails(<String>{productId});
      if (response.error != null) return null;
      for (final item in response.productDetails) {
        if (item.id == productId) return item;
      }
    } catch (error) {
      debugPrint('VIP product preview unavailable: $error');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: Text(_arabic ? 'عضوية WorldVoice VIP' : 'WorldVoice VIP'),
      ),
      body: user == null
          ? Center(child: Text(_arabic
              ? 'سجّل الدخول لعرض العضوية'
              : 'Sign in to view your membership'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(_arabic
                      ? 'تعذر جلب حالة عضويتك. حاول لاحقًا.'
                      : 'Could not load your membership status.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data!.data() ?? <String, dynamic>{};
                final isVip = data['isVip'] == true;
                final expiry = data['vipExpiresAt'];
                final date = expiry is Timestamp ? expiry.toDate() : null;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                  children: [
                    VipMembershipHighlights(isVip: isVip, arabic: _arabic),
                    if (isVip && date != null) ...[
                      const SizedBox(height: 14),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.event_available_outlined),
                          title: Text(_arabic
                              ? 'انتهاء العضوية المسجّل'
                              : 'Recorded membership end date'),
                          subtitle: Text(
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(_arabic ? 'اشتراك VIP الشهري' : 'Monthly VIP membership',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    FutureBuilder<ProductDetails?>(
                      future: _monthlyProduct,
                      builder: (context, product) {
                        final price = product.data?.price;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  price == null
                                      ? (_arabic
                                          ? 'السعر يظهر من المتجر الرسمي بعد إعداد الاشتراك.'
                                          : 'The official store will display the price once configured.')
                                      : (_arabic
                                          ? 'السعر المعروض من المتجر: $price'
                                          : 'Store-listed price: $price'),
                                  key: const ValueKey('vip-monthly-price'),
                                ),
                                const SizedBox(height: 14),
                                FilledButton.icon(
                                  key: const ValueKey('vip-monthly-buy'),
                                  // Billing intentionally unavailable until
                                  // the backend verifies purchases, renewal,
                                  // cancellation, refund and expiry.
                                  onPressed: null,
                                  icon: const Icon(Icons.lock_clock_rounded),
                                  label: Text(_arabic
                                      ? 'الدفع قيد التجهيز والتحقق'
                                      : 'Billing pending secure verification'),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _arabic
                                      ? 'لا يمكن خصم أي مبلغ من هذه الشاشة حاليًا. يجب تفعيل التحقق على السيرفر والاشتراك في Google Play أو App Store أولًا.'
                                      : 'No payment can be charged from this screen yet. Secure server verification and store subscriptions must be configured first.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.workspace_premium_outlined),
                        title: Text(_arabic
                            ? 'شارة VIP الخاصة بك'
                            : 'Your VIP badge'),
                        subtitle: Text(_arabic
                            ? 'نضيف التصميم النهائي بعد اعتماده.'
                            : 'Your final badge design will be added after approval.'),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

/// UI separated from Firebase so the membership layout is testable and
/// does not accidentally promote Free students into the VIP state.
class VipMembershipHighlights extends StatelessWidget {
  const VipMembershipHighlights({
    required this.isVip,
    required this.arabic,
    super.key,
  });

  final bool isVip;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF145A43);
    const gold = Color(0xFFF0CB79);
    final features = <(IconData, String, String)>[
      (
        Icons.menu_book_outlined,
        arabic ? 'دروس أكاديمية غير محدودة' : 'Unlimited Academy lessons',
        arabic ? 'بدل ثلاثة دروس جديدة في اليوم' : 'Instead of three new lessons per day',
      ),
      (
        Icons.block_outlined,
        arabic ? 'بدون إعلانات' : 'Ad-free learning and app access',
        arabic ? 'بدون إعلانات الدروس وفتح التطبيق' : 'No lesson or app-open ads',
      ),
      (
        Icons.visibility_off_outlined,
        arabic ? 'إخفاء زيارات البروفايل' : 'Hide profile visit history',
        arabic ? 'ميزة متاحة في إعدادات VIP' : 'Available in VIP privacy settings',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(23),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF155E48), Color(0xFF0C3A2E)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  size: 54, color: gold),
              const SizedBox(height: 8),
              const Text('WORLDVOICE VIP',
                  style: TextStyle(
                    color: gold,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  )),
              const SizedBox(height: 8),
              Text(
                isVip
                    ? (arabic ? 'عضويتك VIP مفعّلة' : 'Your VIP membership is active')
                    : (arabic ? 'عضويتك الحالية: Free' : 'Your current plan: Free'),
                key: const ValueKey('vip-membership-state'),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(arabic ? 'مميزات VIP الحالية' : 'Current VIP benefits',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 7),
        for (final feature in features)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: green.withValues(alpha: .10),
                child: Icon(feature.$1, color: green),
              ),
              title: Text(feature.$2),
              subtitle: Text(feature.$3),
              trailing: const Icon(Icons.check_circle_outline_rounded,
                  color: green),
            ),
          ),
      ],
    );
  }
}
