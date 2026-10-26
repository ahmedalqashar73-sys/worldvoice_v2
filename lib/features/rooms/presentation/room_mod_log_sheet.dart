import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/room_admin_service.dart';

class RoomModLogSheet extends StatelessWidget {
  const RoomModLogSheet({
    required this.roomId,
    super.key,
  });

  final String roomId;

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final service = RoomAdminService(roomId: roomId);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.receipt_long_rounded),
              title: Text(
                isArabic ? 'سجل المودريتور' : 'Moderator log',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              trailing: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: service.watchModLog(),
                builder: (context, snapshot) {
                  final items =
                      snapshot.data ?? const <Map<String, dynamic>>[];
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        isArabic
                            ? 'لا توجد إجراءات مسجلة بعد.'
                            : 'No moderation actions yet.',
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final rawTime = item['createdAt'];
                      final time =
                          rawTime is Timestamp ? rawTime.toDate() : null;
                      final actor =
                          (item['actorName'] ?? 'Moderator').toString();
                      final target =
                          (item['targetName'] ?? 'Member').toString();
                      final action =
                          (item['action'] ?? 'action').toString();

                      return ListTile(
                        leading: const Icon(Icons.shield_outlined),
                        title: Text(
                          '$actor • ${_label(action, isArabic)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          '$target${time == null ? '' : ' • ${_formatTime(time)}'}',
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _label(String action, bool ar) {
    const en = <String, String>{
      'moderator_assigned': 'made moderator',
      'moderator_removed': 'removed moderator',
      'muted': 'muted',
      'unmuted': 'unmuted',
      'moved_to_listeners': 'moved to listeners',
      'warning': 'warning',
      'auto_kicked_after_3_warnings': 'auto-kicked after 3 warnings',
      'kicked': 'kicked',
    };
    const arabic = <String, String>{
      'moderator_assigned': 'عيّن مودريتور',
      'moderator_removed': 'أزال المودريتور',
      'muted': 'كتم',
      'unmuted': 'ألغى الكتم',
      'moved_to_listeners': 'أنزل للمستمعين',
      'warning': 'تحذير',
      'auto_kicked_after_3_warnings': 'طرد تلقائي بعد 3 تحذيرات',
      'kicked': 'طرد',
    };
    return (ar ? arabic : en)[action] ?? action;
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
