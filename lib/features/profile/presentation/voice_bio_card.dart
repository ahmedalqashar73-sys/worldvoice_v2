import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/media/cloudinary_image_service.dart';

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

  Future<void> _start() async {
    final allowed = await _recorder.hasPermission();
    if (!allowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              widget.code,
              'Microphone permission is required.',
              'يلزم السماح باستخدام الميكروفون.',
              'Se necesita permiso para usar el micrófono.',
            ),
          ),
        ),
      );
      return;
    }

    final directory = await getTemporaryDirectory();
    final path =
        directory.path + '/worldvoice_voice_bio_' + widget.userId + '.m4a';

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
        folder: 'worldvoice/voice_bios/' + widget.userId,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              widget.code,
              'Voice About Me saved.',
              'تم حفظ About Me الصوتي.',
              'Se guardó tu presentación de voz.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              widget.code,
              'Could not save the recording.',
              'تعذر حفظ التسجيل.',
              'No se pudo guardar la grabación.',
            ),
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
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasVoice = widget.existingUrl?.isNotEmpty == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              child: Icon(
                _recording ? Icons.mic_rounded : Icons.record_voice_over_rounded,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t(
                      widget.code,
                      'About Me • Voice',
                      'About Me • صوتي',
                      'Sobre mí • Voz',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _recording
                        ? _t(
                            widget.code,
                            'Recording now…',
                            'جاري التسجيل الآن…',
                            'Grabando ahora…',
                          )
                        : hasVoice
                            ? _t(
                                widget.code,
                                'Voice introduction saved',
                                'تم حفظ التعريف الصوتي',
                                'Presentación de voz guardada',
                              )
                            : _t(
                                widget.code,
                                'Record a short voice introduction',
                                'سجّل تعريفًا صوتيًا قصيرًا عن نفسك',
                                'Graba una breve presentación de voz',
                              ),
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
                tooltip: _t(widget.code, 'Stop & save', 'إيقاف وحفظ', 'Parar y guardar'),
                icon: const Icon(Icons.stop_rounded),
              )
            else ...[
              IconButton.filledTonal(
                onPressed: _start,
                tooltip: hasVoice
                    ? _t(widget.code, 'Record again', 'تسجيل جديد', 'Grabar otra vez')
                    : _t(widget.code, 'Record', 'تسجيل', 'Grabar'),
                icon: const Icon(Icons.mic_rounded),
              ),
              if (hasVoice)
                IconButton(
                  onPressed: _delete,
                  tooltip: _t(widget.code, 'Delete', 'حذف', 'Eliminar'),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

String _t(String code, String en, String ar, String es) {
  if (code == 'ar') return ar;
  if (code == 'es') return es;
  return en;
}
