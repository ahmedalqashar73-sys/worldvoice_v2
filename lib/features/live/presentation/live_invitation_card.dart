import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/live_session_service.dart';

/// Public, non-editable Live invitation reference. An external URL points to
/// the WorldVoice landing page; the in-app card resolves it from Firestore.
class WorldVoiceLiveLinks {
  const WorldVoiceLiveLinks._();
  static const _origin = 'https://worldvoice-v2.onrender.com';

  static String web(String liveId) =>
      '$_origin/live/${Uri.encodeComponent(liveId)}';

  static String? extract(String text) {
    final match = RegExp(
      r'(?:worldvoice://live/|https://worldvoice-v2\.onrender\.com/live/)'
      r'([A-Za-z0-9_-]{3,128})',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(1);
  }
}

/// A live session invitation, not a forwarded chat comment or screenshot.
/// Works in Home posts and direct messages even when an older link format
/// is encountered; the Join action checks the currently active session.
class WorldVoiceLiveInvitationCard extends StatelessWidget {
  const WorldVoiceLiveInvitationCard({
    required this.liveId,
    required this.ar,
    required this.onJoin,
    this.compact = false,
    super.key,
  });

  final String liveId;
  final bool ar;
  final bool compact;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('live_sessions').doc(liveId).snapshots(),
      builder: (context, snapshot) {
        final live = snapshot.data?.data();
        final active = LiveSessionService.isFresh(live);
        final title = (live?['topic'] ?? '').toString().trim();
        final host = (live?['hostName'] ?? 'WorldVoice').toString().trim();
        final photo = (live?['hostPhotoUrl'] ?? '').toString().trim();
        final language = (live?['languageCode'] ?? '').toString().toUpperCase();
        final viewers = (live?['viewerCount'] as num?)?.toInt() ?? 0;

        return Container(
          width: compact ? 242 : double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B3529), Color(0xFF11523D),
                Color(0xFF0D2927)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF3A8970)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.all(compact ? 12 : 16),
                child: Row(children: [
                  CircleAvatar(
                    radius: compact ? 23 : 30,
                    foregroundImage:
                        photo.isEmpty ? null : NetworkImage(photo),
                    backgroundColor: const Color(0xFF34765F),
                    child: photo.isEmpty
                        ? const Icon(Icons.person_rounded,
                            color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(host.isEmpty ? 'WorldVoice' : host,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFFFD988),
                          fontWeight: FontWeight.w900)),
                      Text(title.isEmpty
                          ? (ar ? 'دعوة إلى بث مباشر' : 'Live invitation')
                          : title,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 13 : 16)),
                    ],
                  )),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Row(children: [
                  Icon(Icons.circle, size: 10, color:
                      active ? const Color(0xFFFF5C5C) : Colors.white38),
                  const SizedBox(width: 5),
                  Text(active ? 'LIVE' : (ar ? 'انتهى' : 'Ended'),
                    style: TextStyle(
                      color: active ? const Color(0xFFFFC3BC) : Colors.white60,
                      fontSize: 11, fontWeight: FontWeight.w900)),
                  if (language.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.translate_rounded,
                        size: 15, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(language, style: const TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.w800)),
                  ],
                  const Spacer(),
                  const Icon(Icons.visibility_rounded,
                      size: 15, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text('$viewers',
                    style: const TextStyle(color: Colors.white70)),
                ]),
              ),
              const SizedBox(height: 11),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: FilledButton.icon(
                  onPressed: active ? onJoin : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD67D),
                    foregroundColor: const Color(0xFF18392D),
                    disabledBackgroundColor: Colors.white12,
                    disabledForegroundColor: Colors.white60,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  icon: Icon(active ? Icons.play_arrow_rounded
                      : Icons.live_tv_outlined),
                  label: Text(active
                      ? (ar ? 'دخول البث المباشر' : 'Join this Live')
                      : (ar ? 'البث غير متاح' : 'Live unavailable')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
