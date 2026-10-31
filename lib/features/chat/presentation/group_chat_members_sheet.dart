import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../profile/presentation/public_profile_screen.dart';

/// Group members come from the chat document written by the trusted backend,
/// not from a client-maintained list.
class GroupMembersPreview extends StatelessWidget {
  const GroupMembersPreview({
    required this.chatId,
    this.onTap,
    super.key,
  });

  final String chatId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('chats')
          .doc(chatId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final members = (data['memberIds'] as List?)
            ?.map((id) => id.toString()).toList() ?? <String>[];
        if (members.isEmpty) return const SizedBox.shrink();
        return InkWell(
          key: const ValueKey('group-members-preview'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                const Icon(Icons.groups_rounded, color: Color(0xFF27A87B)),
                const SizedBox(width: 8),
                Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'الأعضاء (${members.length})'
                      : 'Members (${members.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                for (final uid in members.take(4)) ...[
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 4),
                    child: _MemberAvatar(uid: uid, radius: 15),
                  ),
                ],
                const Icon(Icons.chevron_left_rounded),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> showGroupMembersSheet(BuildContext context, String chatId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: .76,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('chats')
            .doc(chatId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load group members.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.data() ?? const <String, dynamic>{};
          final members = (data['memberIds'] as List?)
              ?.map((id) => id.toString()).toList() ?? <String>[];
          final names = data['memberNames'] is Map
              ? Map<String, dynamic>.from(data['memberNames'] as Map)
              : <String, dynamic>{};
          final ar = Localizations.localeOf(context).languageCode == 'ar';
          return Column(
            children: [
              ListTile(
                title: Text(ar ? 'أعضاء المجموعة' : 'Group members',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 19,
                  )),
                subtitle: Text(ar
                    ? '${members.length} عضوًا'
                    : '${members.length} members'),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final uid = members[index];
                    return StreamBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance.collection('users')
                          .doc(uid).snapshots(),
                      builder: (context, memberSnapshot) {
                        final profile = memberSnapshot.data?.data() ??
                            const <String, dynamic>{};
                        final name = (profile['displayName'] ??
                            names[uid] ?? 'WorldVoice member').toString();
                        final username =
                            (profile['username'] ?? '').toString();
                        return ListTile(
                          leading: _MemberAvatar(uid: uid, radius: 24),
                          title: Text(name, maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                          subtitle: Text(username.isEmpty
                              ? (uid == data['ownerId']
                                  ? (ar ? 'منشئ المجموعة' : 'Group creator')
                                  : (ar ? 'عضو' : 'Member'))
                              : '@$username'),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  PublicProfileScreen(userId: uid),
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.uid, required this.radius});
  final String uid;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid)
          .snapshots(),
      builder: (context, snap) {
        final user = snap.data?.data() ?? const <String, dynamic>{};
        final photo = (user['photoUrl'] ?? '').toString().trim();
        final name = (user['displayName'] ?? '').toString();
        return CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFF176B51),
          foregroundImage: photo.isEmpty ? null : NetworkImage(photo),
          child: photo.isEmpty
              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
              : null,
        );
      },
    );
  }
}
