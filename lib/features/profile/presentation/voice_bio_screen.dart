import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/media/cloudinary_image_service.dart';

class VoiceBioScreen extends StatefulWidget {
  const VoiceBioScreen({
    required this.localeController,
    super.key,
  });

  final LocaleController localeController;

  @override
  State<VoiceBioScreen> createState() => _VoiceBioScreenState();
}

class _VoiceBioScreenState extends State<VoiceBioScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  bool _saving = false;
  String? _localPath;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_saving) return;

    if (_recording) {
      final path = await _recorder.stop();
      if (!mounted) return;
      setState(() {
        _recording = false;
        _localPath = path;
      });
      return;
    }

    final allowed = await _recorder.hasPermission();
    if (!allowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_text('Microphone permission is required.', 'نحتاج إذن الميكروفون.', 'Se necesita permiso para el micrófono.'))),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final directory = await getTemporaryDirectory();
    final path = directory.path + '/voice_bio_' + uid + '.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    if (!mounted) return;
    setState(() {
      _recording = true;
      _localPath = null;
    });
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final path = _localPath;
    if (uid == null || path == null || _saving) return;

    setState(() => _saving = true);
    try {
      final upload = await CloudinaryImageService.uploadAudio(
        File(path),
        folder: 'worldvoice/voice_bios/' + uid,
      );

      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'voiceBioUrl': upload.url,
          'voiceBioPublicId': upload.publicId,
          'voiceBioUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_text('Voice About Me saved.', 'تم حفظ About Me الصوتي.', 'About Me de voz guardado.'))),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_text('Could not save the recording.', 'تعذر حفظ التسجيل.', 'No se pudo guardar la grabación.'))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'voiceBioUrl': FieldValue.delete(),
        'voiceBioPublicId': FieldValue.delete(),
        'voiceBioUpdatedAt': FieldValue.delete(),
      },
      SetOptions(merge: true),
    );

    if (mounted) Navigator.of(context).pop();
  }

  String _text(String en, String ar, String es) {
    final code = widget.localeController.locale?.languageCode ?? 'en';
    if (code == 'ar') return ar;
    if (code == 'es') return es;
    return en;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(_text('Voice About Me', 'About Me الصوتي', 'About Me de voz')),
      ),
      body: uid == null
          ? const Center(child: Text('No signed-in user'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, snapshot) {
                final existing = snapshot.data?.data()?['voiceBioUrl'] as String?;
                return ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    const SizedBox(height: 24),
                    CircleAvatar(
                      radius: 58,
                      child: Icon(
                        _recording ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                        size: 54,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      _recording
                          ? _text('Recording… tap stop when finished.', 'جاري التسجيل… اضغط إيقاف عند الانتهاء.', 'Grabando… pulsa detener al terminar.')
                          : _text('Record a short voice introduction for your profile.', 'سجّل مقدمة صوتية قصيرة تظهر في بروفايلك.', 'Graba una presentación de voz corta para tu perfil.'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _toggleRecording,
                      icon: Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded),
                      label: Text(
                        _recording
                            ? _text('Stop recording', 'إيقاف التسجيل', 'Detener grabación')
                            : _text('Record', 'تسجيل', 'Grabar'),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                      ),
                    ),
                    if (_localPath != null && !_recording) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.cloud_upload_rounded),
                        label: Text(
                          _saving
                              ? _text('Saving…', 'جاري الحفظ…', 'Guardando…')
                              : _text('Save to profile', 'حفظ في البروفايل', 'Guardar en perfil'),
                        ),
                      ),
                    ],
                    if (existing != null && existing.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.check_circle_rounded),
                          title: Text(_text('Voice About Me is active', 'About Me الصوتي مفعّل', 'About Me de voz activo')),
                          subtitle: Text(_text('Record again to replace it.', 'يمكنك التسجيل مرة أخرى لاستبداله.', 'Graba otra vez para reemplazarlo.')),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _delete,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(_text('Delete voice bio', 'حذف التسجيل الصوتي', 'Eliminar audio')),
                      ),
                    ],
                  ],
                );
              },
            ),
    );
  }
}
