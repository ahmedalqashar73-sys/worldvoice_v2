import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/room_moderation_models.dart';
import '../services/room_feature_service.dart';

class RoomRatingSheet extends StatefulWidget {
  const RoomRatingSheet({
    required this.roomId,
    required this.participants,
    super.key,
  });

  final String roomId;
  final List<RoomParticipant> participants;

  @override
  State<RoomRatingSheet> createState() => _RoomRatingSheetState();
}

class _RoomRatingSheetState extends State<RoomRatingSheet> {
  late final RoomFeatureService _service;
  final Map<String, int> _ratings = <String, int>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _service = RoomFeatureService(roomId: widget.roomId);
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final speakers = widget.participants
        .where(
          (participant) =>
              participant.isOnStage && participant.userId != myUid,
        )
        .toList(growable: false);
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .62,
        child: Column(
          children: [
            ListTile(
              title: Text(
                isArabic ? 'قيّم المتحدثين' : 'Rate the speakers',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                isArabic
                    ? 'التقييم اختياري ويساعد على تحسين تجربة الغرف.'
                    : 'Rating is optional and helps improve room quality.',
              ),
              trailing: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: speakers.isEmpty
                  ? Center(
                      child: Text(
                        isArabic
                            ? 'لا يوجد متحدثون آخرون للتقييم.'
                            : 'No other speakers to rate.',
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: speakers.length,
                      itemBuilder: (context, index) {
                        final speaker = speakers[index];
                        final selected = _ratings[speaker.userId] ?? 0;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage:
                                      speaker.photoUrl?.isNotEmpty == true
                                          ? NetworkImage(speaker.photoUrl!)
                                          : null,
                                  child: speaker.photoUrl?.isNotEmpty == true
                                      ? null
                                      : const Icon(Icons.person_rounded),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    speaker.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                for (var star = 1; star <= 5; star++)
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 30,
                                      minHeight: 34,
                                    ),
                                    onPressed: () => setState(
                                      () => _ratings[speaker.userId] = star,
                                    ),
                                    icon: Icon(
                                      star <= selected
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      size: 25,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed:
                          _saving ? null : () => Navigator.pop(context),
                      child: Text(isArabic ? 'تخطي' : 'Skip'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving || _ratings.isEmpty
                          ? null
                          : () async {
                              setState(() => _saving = true);
                              try {
                                await Future.wait(
                                  _ratings.entries.map(
                                    (entry) => _service.submitRating(
                                      targetUserId: entry.key,
                                      stars: entry.value,
                                    ),
                                  ),
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _saving = false);
                                }
                              }
                            },
                      child: Text(isArabic ? 'إرسال' : 'Submit'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
