import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/media/cloudinary_image_service.dart';
import 'voice_bio_player.dart';

class VoiceBioCard extends StatefulWidget {
  const VoiceBioCard({
    required this.userId,
    required this.code,
    required this.existingUrl,
    super.key,
  });

  final String userId;
  final String code;
  final String? existingUrl;

  @override
  State<VoiceBioCard> createState() => _VoiceBioCardState();
}

class _VoiceBioCardState extends State<VoiceBioCard> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  bool _saving = false;
  String? _voiceUrl;

  @override
  void initState() {
    super.initState();
    _voiceUrl = widget.existingUrl;
  }

  @override
  void didUpdateWidget(covariant VoiceBioCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.existingUrl != widget.existingUrl && !_recording && !_saving) {
      _voiceUrl = widget.existingUrl;
    }
  }

  Future<void> _start() async {
    final allowed = await _recorder.hasPermission();
    if (!allowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.of(widget.code).profile('microphonePermission'),
          ),
        ),
      );
      return;
    }

    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/worldvoice_voice_bio_${widget.userId}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    if (mounted) setState(() => _recording = true);
  }

  Future<void> _stopAndSave() async {
    if (!_recording || _saving) return;

    setState(() {
      _recording = false;
      _saving = true;
    });

    try {
      final path = await _recorder.stop();
      if (path == null || path.isEmpty) {
        throw StateError('Recording path is missing');
      }

      final upload = await CloudinaryImageService.uploadAudio(
        File(path),
        folder: 'worldvoice/voice_bios/${widget.userId}',
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({
        'voiceBioUrl': upload.url,
        'voiceBioPublicId': upload.publicId,
        'voiceBioUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _voiceUrl = upload.url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.of(widget.code).profile('voiceSaved'),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.of(widget.code).profile('voiceSaveFailed'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .set({
      'voiceBioUrl': FieldValue.delete(),
      'voiceBioPublicId': FieldValue.delete(),
      'voiceBioUpdatedAt': FieldValue.delete(),
    }, SetOptions(merge: true));
    if (mounted) setState(() => _voiceUrl = null);
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasVoice = _voiceUrl?.isNotEmpty == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    _recording
                        ? Icons.mic_rounded
                        : Icons.record_voice_over_rounded,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.of(widget.code).profile('voiceAboutMe'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _recording
                            ? AppStrings.of(widget.code).profile('recordingNow')
                            : hasVoice
                                ? AppStrings.of(widget.code)
                                    .profile('voiceIntroSaved')
                                : AppStrings.of(widget.code)
                                    .profile('recordVoiceIntro'),
                      ),
                    ],
                  ),
                ),
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_recording)
                  IconButton.filled(
                    onPressed: _stopAndSave,
                    tooltip:
                        AppStrings.of(widget.code).profile('stopAndSave'),
                    icon: const Icon(Icons.stop_rounded),
                  )
                else ...[
                  IconButton.filledTonal(
                    onPressed: _start,
                    tooltip: hasVoice
                        ? AppStrings.of(widget.code).profile('recordAgain')
                        : AppStrings.of(widget.code).profile('record'),
                    icon: const Icon(Icons.mic_rounded),
                  ),
                  if (hasVoice)
                    IconButton(
                      onPressed: _delete,
                      tooltip: AppStrings.of(widget.code).profile('delete'),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                ],
              ],
            ),
            if (hasVoice && _voiceUrl != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: VoiceBioPlayer(
                  url: _voiceUrl!,
                  code: widget.code,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

