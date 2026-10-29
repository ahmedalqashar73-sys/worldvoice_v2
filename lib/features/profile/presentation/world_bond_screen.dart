// ignore_for_file: prefer_interpolation_to_compose_strings, use_null_aware_elements
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../rooms/data/room_backend_config.dart';

/// Server-authenticated social features. Never mutate wallet/VIP from client.
class WorldBondApi {
  static Future<Map<String, dynamic>> request(String endpoint,
      {Map<String, dynamic>? body, String? idempotencyKey}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('SIGN_IN_REQUIRED');
    final base = Uri.parse(RoomBackendConfig.economyBaseUrl.trim());
    if (base.scheme != 'https' || !base.hasAuthority) {
      throw StateError('WorldVoice backend unavailable');
    }
    final uri = endpointUri(base, endpoint);
    final token = await user.getIdToken();
    final headers = <String, String>{
      'Authorization': 'Bearer ' + (token ?? ''),
      'Content-Type': 'application/json',
      if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
    };
    final response = await (body == null
        ? http.get(uri, headers: headers)
        : http.post(uri, headers: headers, body: jsonEncode(body)))
        .timeout(const Duration(seconds: 25));
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw StateError('Invalid server response');
    final data = Map<String, dynamic>.from(decoded);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError((data['error'] ?? 'Request rejected').toString());
    }
    return data;
  }

  /// Build authenticated WorldBond URLs without encoding query data as a path.
  static Uri endpointUri(Uri base, String endpoint) {
    final route = Uri.parse(endpoint);
    if (base.scheme != 'https' || !base.hasAuthority ||
        route.hasScheme || route.hasAuthority || route.hasFragment ||
        route.path.isEmpty || route.path.startsWith('/')) {
      throw StateError('Invalid WorldBond endpoint');
    }
    final prefix = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    return base.replace(
      path: prefix + '/' + route.path,
      query: route.hasQuery ? route.query : null,
    );
  }

  static String newKey() {
    final random = Random.secure();
    return List<int>.generate(24, (_) => random.nextInt(256))
        .map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  }
}

class WorldBondScreen extends StatefulWidget {
  const WorldBondScreen({super.key, this.peerId, this.peerName});
  final String? peerId;
  final String? peerName;
  @override
  State<WorldBondScreen> createState() => _WorldBondScreenState();
}

class _WorldBondScreenState extends State<WorldBondScreen> {
  static const green = Color(0xFF0A8058);
  Map<String, dynamic>? _data;
  String? _error;
  bool _busy = false;
  final Map<String, String> _paymentKeys = {};
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String label(String arabic, String english) => ar ? arabic : english;
  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get self => widget.peerId == null || widget.peerId == uid;
  List<Map<String, dynamic>> group(String key) {
    return (_data?[key] as List? ?? []).whereType<Map>()
        .map((v) => Map<String, dynamic>.from(v)).toList();
  }

  @override
  void initState() { super.initState(); _refresh(); }

  Future<void> _refresh() async {
    try {
      final query = self ? '' :
        '?peerId=' + Uri.encodeQueryComponent(widget.peerId!);
      final data = await WorldBondApi.request('world-bond/overview' + query);
      if (mounted) setState(() { _data = data; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _post(String route, Map<String, dynamic> data,
      {String? key}) async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      await WorldBondApi.request(route, body: data, idempotencyKey: key);
      if (key != null) {
        _paymentKeys.remove((data['itemId'] ?? data['giftId']).toString());
      }
      await _refresh();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _other(Map<String, dynamic> bond) {
    final members = (bond['members'] as List? ?? []).cast<String>();
    for (final id in members) {
      if (id != uid) return id;
    }
    return null;
  }

  Future<void> _respond(Map<String, dynamic> bond, String action) async {
    final peer = _other(bond);
    if (peer == null) return;
    await _post('world-bond/respond',
      {'peerId': peer, 'type': bond['type'], 'decision': action});
  }

  Future<void> _wishEdit() async {
    final catalog = group('catalog');
    final selected = group('wishes').map((e) => e['id'].toString()).toSet();
    final result = await showModalBottomSheet<List<String>>(
      context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, update) =>
        SafeArea(child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * .60,
          child: Column(children: [
            const SizedBox(height: 10),
            Text(label('اختر حتى ثلاث رغبات', 'Choose up to three wishes'),
              style: Theme.of(ctx).textTheme.titleLarge),
            Expanded(child: ListView(children: [
              for (final item in catalog)
                CheckboxListTile(
                  value: selected.contains(item['id']),
                  title: Text(item['name'].toString()),
                  subtitle: Text(item['priceCoins'].toString() + ' coins'),
                  onChanged: (v) => update(() {
                    if (v == false) selected.remove(item['id']);
                    if (v == true && selected.length < 3) {
                      selected.add(item['id'].toString());
                    }
                  }),
                ),
            ])),
            FilledButton(onPressed: () => Navigator.pop(ctx, selected.toList()),
              child: Text(label('حفظ', 'Save'))),
            const SizedBox(height: 12),
          ]),
        ))),
    );
    if (result != null) {
      await _post('world-bond/wishlist', {'items': result});
    }
  }

  Future<void> _giftVip(Map<String, dynamic> wish) async {
    if (self || wish['type'] != 'vip') return;
    final agreed = await showDialog<bool>(
      context: context, builder: (ctx) => AlertDialog(
        title: Text(label('تأكيد إهداء VIP', 'Confirm VIP gift')),
        content: Text(label(
          'سيتم خصم العملات من محفظتك بواسطة السيرفر بعد التحقق من السعر '
          'والرصيد وشروط إهداء الأصدقاء. هل توافق؟',
          'The server checks the official item price, your balance and '
          'friend eligibility before deducting coins. Continue?',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text(label('إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text(label('تأكيد', 'Confirm'))),
        ],
      ),
    );
    if (agreed != true) return;
    await _post('store/purchase',
      {'itemId': wish['id'], 'recipientId': widget.peerId},
      key: _paymentKeys.putIfAbsent(
        wish['id'].toString(), WorldBondApi.newKey));
  }

  Future<void> _openChallenge(Map<String, dynamic> bond) async {
    final peer = _other(bond);
    if (peer == null || _busy) return;
    try {
      final query = 'world-bond/challenge?peerId=' +
          Uri.encodeQueryComponent(peer) +
          '&type=' + Uri.encodeQueryComponent(bond['type'].toString());
      final exercise = await WorldBondApi.request(query);
      if (!mounted) return;
      if (exercise['alreadyAttempted'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(label('أجبت على تحدي اليوم بالفعل',
            'You already answered today')),
        ));
        return;
      }
      int? selected;
      final index = await showDialog<int>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, update) => AlertDialog(
            title: Text(label('تحدي الشريك التعليمي',
              'Partner language challenge')),
            content: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(exercise['question'].toString()),
                const SizedBox(height: 15),
                for (var i = 0;
                    i < (exercise['choices'] as List).length; i++)
                  ChoiceChip(
                    label: Text((exercise['choices'] as List)[i].toString()),
                    selected: selected == i,
                    onSelected: (_) => update(() => selected = i),
                  ),
              ],
            )),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(label('إلغاء', 'Cancel'))),
              FilledButton(
                onPressed: selected == null ? null :
                    () => Navigator.pop(ctx, selected),
                child: Text(label('تأكيد الإجابة', 'Submit answer'))),
            ],
          ),
        ),
      );
      if (index == null || !mounted) return;
      setState(() { _busy = true; _error = null; });
      final result = await WorldBondApi.request('world-bond/challenge/answer',
        body: {'peerId': peer, 'type': bond['type'],
          'answerIndex': index});
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(result['correct'] == true
              ? label('إجابة صحيحة!', 'Correct!')
              : label('جرّب تعلمها غدًا', 'Practice again tomorrow')),
          content: Text(result['explanation'].toString() +
              '\n' + (result['pairCompleted'] == true
                ? label('أنت وشريكك أكملتما التحدي! +50 XP للعلاقة',
                  'Both partners completed the challenge! +50 bond XP')
                : label('تُحتسب المكافأة بعد الإجابتين الصحيحتين',
                  'XP unlocks when both partners answer correctly'))),
          actions: [TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(label('حسنًا', 'OK')))],
        ),
      );
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _giftRegular(Map<String, dynamic> wish) async {
    if (self || widget.peerId == null) return;
    final id = wish['id'].toString();
    if (!RegExp(r'^gift__wv_gift_[0-9]{3}$').hasMatch(id)) {
      setState(() => _error = label(
        'الهدية غير مؤهلة للإرسال المباشر.',
        'This gift is not available for direct gifting.'));
      return;
    }
    final agreed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label('تأكيد إرسال الهدية', 'Confirm gift')),
        content: Text(label(
          'سيتحقق السيرفر من الرصيد والسعر والمتابعة المتبادلة '
          'والمحادثة الخاصة قبل خصم العملات.',
          'The server verifies balance, price, mutual following '
          'and active private chat before charging coins.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(label('إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text(label('إرسال', 'Send'))),
        ],
      ),
    );
    if (agreed != true || _busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      final chat = await WorldBondApi.request(
        'world-bond/chat-context?peerId=' +
          Uri.encodeQueryComponent(widget.peerId!));
      final key = _paymentKeys.putIfAbsent(id, WorldBondApi.newKey);
      await WorldBondApi.request('gift/send', body: {
        'context': 'chat', 'contextId': chat['chatId'],
        'recipientId': widget.peerId,
        'giftId': id.substring('gift__'.length), 'quantity': 1,
      }, idempotencyKey: key);
      _paymentKeys.remove(id);
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const kinds = <String, IconData>{
      'language': Icons.translate_rounded,
      'friend': Icons.handshake_rounded,
      'duo': Icons.favorite_rounded,
    };
    String kind(String code) => switch (code) {
      'language' => label('رفيق اللغة', 'Language partner'),
      'friend' => label('صديق مميز', 'Close friend'),
      'duo' => label('ثنائي WorldVoice', 'WorldVoice duo'),
      _ => code,
    };
    final bonds = group('bonds').where((bond) => self ||
        (bond['members'] as List? ?? []).contains(widget.peerId)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('WorldBond'),
        foregroundColor: Colors.white, backgroundColor: green),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [green, Color(0xFF064B37)]),
              borderRadius: BorderRadius.circular(20)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.diversity_2_rounded,
                color: Color(0xFFFFE4A0), size: 35),
              const SizedBox(height: 8),
              Text(self ? label('روابطي', 'My connections')
                  : (widget.peerName ?? 'WorldVoice'),
                style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 22)),
              Text(label('علاقات بالتراضي، وتعلم مشترك، بلا شراء نقاط',
                'Mutual connections and practice without paid relationship XP'),
                style: const TextStyle(color: Colors.white70)),
            ]),
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) Card(child: ListTile(
            leading: const Icon(Icons.warning_amber, color: Colors.orange),
            title: Text(_error!),
            trailing: IconButton(icon: const Icon(Icons.refresh),
              onPressed: _refresh),
          )),
          const SizedBox(height: 18),
          Text(label('العلاقات والدعوات', 'Relationships and invitations'),
            style: Theme.of(context).textTheme.titleLarge),
          if (!self && _data != null)
            for (final kindCode in kinds.keys)
              if (!bonds.any((b) => b['type'] == kindCode &&
                  (b['status'] == 'pending' || b['status'] == 'active')))
                Card(child: ListTile(
                  leading: Icon(kinds[kindCode], color: green),
                  title: Text(kind(kindCode)),
                  subtitle: Text(label('صلاحية الدعوة 48 ساعة',
                    '48-hour invitation')),
                  trailing: FilledButton(
                    onPressed: _busy ? null : () => _post(
                      'world-bond/invite',
                      {'peerId': widget.peerId, 'type': kindCode}),
                    child: Text(label('دعوة', 'Invite'))),
                )),
          if (bonds.isEmpty && self)
            ListTile(title: Text(label(
              'افتح ملف صديق لدعوته إلى WorldBond',
              'Open a friend profile to invite them to WorldBond'))),
          for (final bond in bonds)
            Card(child: Padding(padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: Icon(kinds[bond['type']] ?? Icons.people, color: green),
                    title: Text(kind(bond['type'].toString())),
                    subtitle: Text(bond['status'] == 'pending'
                      ? label('بانتظار القبول', 'Awaiting acceptance')
                      : 'Lv' + bond['level'].toString() + ' • ' +
                        bond['xp'].toString() + ' XP'),
                  ),
                  if (bond['status'] == 'pending')
                    Wrap(spacing: 8, children: [
                      if (bond['recipientId'] == uid) ...[
                        OutlinedButton(onPressed: _busy ? null :
                          () => _respond(bond, 'decline'),
                          child: Text(label('رفض', 'Decline'))),
                        FilledButton(onPressed: _busy ? null :
                          () => _respond(bond, 'accept'),
                          child: Text(label('قبول', 'Accept'))),
                      ] else
                        TextButton(onPressed: _busy ? null :
                          () => _respond(bond, 'cancel'),
                          child: Text(label('إلغاء الدعوة', 'Cancel invite'))),
                    ]),
                  if (bond['status'] == 'active') ...[
                    LinearProgressIndicator(
                      value: ((bond['xp'] as num? ?? 0).toDouble() / 2200)
                        .clamp(0.0, 1.0), color: green),
                    const SizedBox(height: 8),
                    Text(label('أكمل تمرينك مع شريكك اليوم. يتطلب التقدم '
                      'تأكيدكما معًا، ولا يمنح عملات.',
                      'Both partners confirm daily practice. Friendship XP '
                      'is non-monetary.')),
                    Wrap(spacing: 6, children: [
                      FilledButton.icon(
                        onPressed: _busy ? null : () {
                          final peer = _other(bond);
                          if (peer != null) {
                            _post('world-bond/practice',
                              {'peerId': peer, 'type': bond['type']});
                          }
                        },
                        icon: const Icon(Icons.menu_book),
                        label: Text(label('أنجزت تدريب اليوم', 'Daily practice'))),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : () => _openChallenge(bond),
                        icon: const Icon(Icons.psychology_alt_outlined),
                        label: Text(label('تحدي لغوي', 'Language quiz'))),
                      TextButton(onPressed: _busy ? null :
                        () => _respond(bond, 'leave'),
                        child: Text(label('إنهاء العلاقة', 'End relation'))),
                    ]),
                  ],
                ]),
            )),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: Text(label('قائمة الرغبات', 'Wishlist'),
              style: Theme.of(context).textTheme.titleLarge)),
            if (self) TextButton.icon(onPressed: _busy ? null : _wishEdit,
              icon: const Icon(Icons.edit), label: Text(label('تعديل', 'Edit'))),
          ]),
          for (final wish in group('wishes'))
            Card(child: ListTile(
              leading: Icon(wish['type'] == 'vip'
                  ? Icons.workspace_premium : Icons.card_giftcard, color: green),
              title: Text(wish['name'].toString()),
              subtitle: Text(wish['priceCoins'].toString() + ' coins'),
              trailing: self ? null : OutlinedButton(
                onPressed: _busy ? null : () => wish['type'] == 'vip'
                    ? _giftVip(wish) : _giftRegular(wish),
                child: Text(wish['type'] == 'vip'
                    ? label('إهداء VIP', 'Gift VIP')
                    : label('إرسال هدية', 'Send gift')),
              ),
            )),
          if (group('wishes').isEmpty)
            Text(label('لا توجد رغبات منشورة بعد',
              'No published wishlist items')),
          const SizedBox(height: 6),
          Text(label('إهداء الهدايا يتطلب متابعة متبادلة ومحادثة '
            'نشطة، ويعتمد الخصم على السيرفر فقط.',
            'Gifts require mutual following and an active private chat; '
            'only the server deducts coins.'),
            style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 22),
          Text(label('جدار الهدايا', 'Gift wall'),
            style: Theme.of(context).textTheme.titleLarge),
          for (final record in group('wall'))
            ListTile(leading: const Icon(Icons.redeem, color: green),
              title: Text(record['itemId'].toString()),
              subtitle: Text(label('هدية مسجلة على السيرفر',
                'Server recorded gift'))),
          if (group('wall').isEmpty)
            Text(label('لا توجد هدايا مسجلة حتى الآن',
              'No recorded gifts yet')),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}
