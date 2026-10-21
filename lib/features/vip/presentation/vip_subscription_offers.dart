import 'package:flutter/material.dart';

import '../services/vip_subscription_service.dart';

class VipSubscriptionOffers extends StatefulWidget {
  const VipSubscriptionOffers({required this.ar, super.key});
  final bool ar;

  @override
  State<VipSubscriptionOffers> createState() => _VipSubscriptionOffersState();
}

class _VipSubscriptionOffersState extends State<VipSubscriptionOffers> {
  final VipSubscriptionService _subscriptions = VipSubscriptionService.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _subscriptions.addListener(_update);
    _subscriptions.initialize();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _subscriptions.removeListener(_update);
    super.dispose();
  }

  Future<void> _submit(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.ar
            ? 'تعذر بدء عملية المتجر. تأكد من إعداد المتجر والمحاولة مجددًا.'
            : 'Could not start store billing. Please try again.'),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offers = _subscriptions.offers;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.ar ? 'اشتراك VIP Gold' : 'VIP Gold Subscription',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              widget.ar
                  ? 'سيتم عرض السعر الرسمي من Google Play أو App Store مباشرة عند اعتماد الاشتراكات.'
                  : 'Approved subscription prices are shown directly by Google Play or the App Store.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_subscriptions.loading)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (offers.isEmpty && !_subscriptions.loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(widget.ar
                    ? 'الاشتراك غير متاح للشراء حاليًا. جارٍ تجهيز ربط المتاجر.'
                    : 'VIP billing is not enabled yet. Store setup is pending.'),
              ),
            for (final offer in offers)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.workspace_premium_rounded,
                    color: Color(0xFFA97C2B)),
                title: Text(offer.product.title),
                subtitle: Text(offer.product.description,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: FilledButton(
                  onPressed: _busy || !_subscriptions.billingApproved
                      ? null
                      : () => _submit(() => _subscriptions.purchase(offer)),
                  child: Text(offer.product.price),
                ),
              ),
            if (_subscriptions.billingApproved)
              TextButton.icon(
                onPressed: _busy
                    ? null : () => _submit(_subscriptions.restore),
                icon: const Icon(Icons.restore_rounded),
                label: Text(widget.ar
                    ? 'استعادة مشتريات VIP' : 'Restore VIP purchases'),
              ),
            Text(
              widget.ar
                  ? 'يتم التجديد والإلغاء من حساب المتجر. لن تُفعّل العضوية إلا بعد التحقق من الشراء على خادم WorldVoice.'
                  : 'Renewal and cancellation are managed by your platform store. WorldVoice grants VIP only after server verification.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_subscriptions.message != null &&
                _subscriptions.billingApproved)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_subscriptions.message!,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}
