import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/room_shop_service.dart';

/// Owner searches verified backend public identities. Regular users retain
/// their existing followed-contacts gifting permissions.
Future<ShopGiftRecipient?> pickStoreGiftRecipient(
  BuildContext context, RoomShopService shop, bool ar,
) async {
  final isOwner = await shop.ownerAccess;
  if (!context.mounted) return null;
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return null;

  if (!isOwner) {
    final contacts = await FirebaseFirestore.instance
        .collection('users').doc(currentUser.uid).collection('following').get();
    if (!context.mounted) return null;
    return showDialog<ShopGiftRecipient>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: Text(ar ? 'اختر صديقًا' : 'Choose a friend'),
        children: [
          if (contacts.docs.isEmpty)
            Padding(padding: const EdgeInsets.all(16),
              child: Text(ar ? 'لا يوجد أصدقاء بعد' : 'No friends found')),
          for (final doc in contacts.docs)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialog,
                ShopGiftRecipient(uid: doc.id,
                  displayName: (doc.data()['displayName'] ?? doc.id).toString())),
              child: Text((doc.data()['displayName'] ?? doc.id).toString()),
            ),
        ],
      ),
    );
  }

  final controller = TextEditingController();
  var searching = false;
  String? error;
  List<ShopGiftRecipient> matches = const [];
  try {
    return await showDialog<ShopGiftRecipient>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialogContext, update) {
          Future<void> search() async {
            final term = controller.text.trim();
            if (term.length < 2) {
              update(() => error = ar ? 'اكتب حرفين على الأقل' : 'Enter at least 2 characters');
              return;
            }
            update(() { searching = true; error = null; matches = const []; });
            try {
              final result = await shop.searchGiftRecipients(term);
              if (!dialogContext.mounted) return;
              update(() { matches = result; searching = false; });
            } catch (_) {
              if (!dialogContext.mounted) return;
              update(() {
                searching = false;
                error = ar ? 'تعذر البحث عن المستخدمين' : 'Search unavailable';
              });
            }
          }
          return AlertDialog(
            title: Text(ar ? 'إهداء لأي مستخدم' : 'Gift any user'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: ar ? 'الاسم أو اسم المستخدم أو ID' : 'Name, username or ID',
                      prefixIcon: const Icon(Icons.search),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => search(),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: searching ? null : search,
                    icon: const Icon(Icons.search),
                    label: Text(ar ? 'بحث' : 'Search'),
                  ),
                  if (searching) const LinearProgressIndicator(),
                  if (error != null)
                    Text(error!, style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
                  if (!searching && matches.isEmpty && error == null)
                    Text(ar ? 'اكتب الاسم أو المعرّف للبحث' : 'Search by name or ID'),
                  if (matches.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: matches.length,
                        itemBuilder: (_, index) {
                          final person = matches[index];
                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(person.displayName),
                            subtitle: Text(person.username.isNotEmpty
                              ? '@${person.username} • ${person.customId.isNotEmpty ? person.customId : person.uid}'
                              : person.customId.isNotEmpty ? person.customId : person.uid),
                            onTap: () => Navigator.pop(dialog, person),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text(ar ? 'إلغاء' : 'Cancel'),
            )],
          );
        },
      ),
    );
  } finally {
    controller.dispose();
  }
}

/// Returns null on cancellation, zero for permanent, or a supported day count.
Future<int?> pickCosmeticGiftDuration(
  BuildContext context, bool ar, int permanentPrice,
) async {
  const durations = <int>[3, 7, 10, 15, 30, 0];
  const rates = <int>[15, 25, 35, 45, 60, 100];
  return showDialog<int>(
    context: context,
    builder: (dialog) => SimpleDialog(
      title: Text(ar ? 'اختر مدة الهدية' : 'Gift duration'),
      children: [
        for (var i = 0; i < durations.length; i++)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialog, durations[i]),
            child: Row(children: [
              Expanded(child: Text(durations[i] == 0
                ? (ar ? 'دائمًا' : 'Permanent')
                : '${durations[i]} ${ar ? 'أيام' : 'days'}')),
              Text('${((permanentPrice * rates[i] + 499) ~/ 500) * 5} 🪙'),
            ]),
          ),
      ],
    ),
  );
}
