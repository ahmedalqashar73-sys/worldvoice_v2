import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/media/cloudinary_image_service.dart';
import '../data/room_feature_models.dart';
import '../services/room_feature_service.dart';

class RoomMusicSheet extends StatefulWidget {
  const RoomMusicSheet({
    required this.roomId,
    required this.isHost,
    super.key,
  });

  final String roomId;
  final bool isHost;

  @override
  State<RoomMusicSheet> createState() => _RoomMusicSheetState();
}

class _RoomMusicSheetState extends State<RoomMusicSheet> {
  late final RoomFeatureService _service;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _service = RoomFeatureService(roomId: widget.roomId);
  }

  Future<void> _pickTrack() async {
    final picked = await FilePicker.pickFile(type: FileType.audio);
    if (picked == null || picked.path == null) return;

    setState(() => _uploading = true);
    try {
      final upload = await CloudinaryImageService.uploadAudio(
        File(picked.path!),
        folder: 'worldvoice/rooms/${widget.roomId}/music',
      );
      await _service.setMusic(
        title: picked.name,
        url: upload.url,
        playing: true,
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    return SafeArea(
      child: StreamBuilder<RoomFeatureState>(
        stream: _service.watchState(),
        builder: (context, snapshot) {
          final state = snapshot.data;
          final hasTrack = state?.musicUrl?.isNotEmpty == true;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.music_note_rounded),
                  title: Text(
                    isArabic ? 'موسيقى الغرفة' : 'Room music',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    state?.musicTitle ??
                        (isArabic ? 'لا يوجد مسار' : 'No track selected'),
                  ),
                ),
                if (hasTrack)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: widget.isHost
                              ? () => _service.setMusic(
                                    title: state!.musicTitle,
                                    url: state.musicUrl,
                                    playing: !state.musicPlaying,
                                  )
                              : null,
                          icon: Icon(
                            state?.musicPlaying == true
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          label: Text(
                            state?.musicPlaying == true
                                ? (isArabic ? 'إيقاف' : 'Pause')
                                : (isArabic ? 'تشغيل' : 'Play'),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (widget.isHost) ...[
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _uploading ? null : _pickTrack,
                    icon: _uploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.library_music_rounded),
                    label: Text(
                      isArabic ? 'اختيار موسيقى' : 'Choose music',
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
