import 'package:flutter/material.dart';

import '../data/room_moderation_models.dart';
import '../data/room_stage_models.dart';
import '../services/room_admin_service.dart';

class RoomMembersSheet extends StatelessWidget {
  const RoomMembersSheet({
    required this.roomId,
    required this.participants,
    required this.isHost,
    required this.isModerator,
    super.key,
  });

  final String roomId;
  final List<RoomParticipant> participants;
  final bool isHost;
  final bool isModerator;

  bool get _canModerate => isHost || isModerator;

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final admin = RoomAdminService(roomId: roomId);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.groups_rounded),
              title: Text(
                isArabic ? 'أعضاء الغرفة' : 'Room members',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text('${participants.length}'),
              trailing: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final participant = participants[index];
                  final protected =
                      participant.role == RoomMemberRole.host;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          participant.photoUrl?.isNotEmpty == true
                              ? NetworkImage(participant.photoUrl!)
                              : null,
                      child: participant.photoUrl?.isNotEmpty == true
                          ? null
                          : const Icon(Icons.person_rounded),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            participant.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (participant.isModerator) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.shield_rounded,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      _subtitle(participant, isArabic),
                    ),
                    trailing: !_canModerate || protected
                        ? null
                        : PopupMenuButton<String>(
                            onSelected: (value) async {
                              try {
                                switch (value) {
                                  case 'mute':
                                    await admin.setForcedMute(
                                      participant: participant,
                                      value: !participant.forcedMuted,
                                    );
                                    break;
                                  case 'down':
                                    await admin.moveDown(participant);
                                    break;
                                  case 'warn':
                                    await admin.warn(participant);
                                    break;
                                  case 'kick':
                                    await admin.kick(participant);
                                    break;
                                  case 'moderator':
                                    if (isHost) {
                                      await admin.setModerator(
                                        participant: participant,
                                        value: !participant.isModerator,
                                      );
                                    }
                                    break;
                                }
                              } catch (error) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(error.toString())),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'mute',
                                child: Text(
                                  participant.forcedMuted
                                      ? (isArabic ? 'إلغاء الكتم' : 'Unmute')
                                      : (isArabic ? 'كتم' : 'Mute'),
                                ),
                              ),
                              if (participant.isOnStage)
                                PopupMenuItem(
                                  value: 'down',
                                  child: Text(
                                    isArabic
                                        ? 'إنزال من الستيج'
                                        : 'Move to listeners',
                                  ),
                                ),
                              PopupMenuItem(
                                value: 'warn',
                                child: Text(
                                  isArabic
                                      ? 'تحذير (${participant.warningCount}/3)'
                                      : 'Warning (${participant.warningCount}/3)',
                                ),
                              ),
                              if (isHost)
                                PopupMenuItem(
                                  value: 'moderator',
                                  child: Text(
                                    participant.isModerator
                                        ? (isArabic
                                            ? 'إزالة Moderator'
                                            : 'Remove moderator')
                                        : (isArabic
                                            ? 'تعيين Moderator'
                                            : 'Make moderator'),
                                  ),
                                ),
                              PopupMenuItem(
                                value: 'kick',
                                child: Text(
                                  isArabic ? 'طرد من الغرفة' : 'Kick',
                                ),
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
    );
  }

  String _subtitle(RoomParticipant participant, bool isArabic) {
    final role = participant.role.label;
    final warning = participant.warningCount > 0
        ? ' • ${isArabic ? 'تحذيرات' : 'warnings'}: ${participant.warningCount}/3'
        : '';
    return '$role$warning';
  }
}
