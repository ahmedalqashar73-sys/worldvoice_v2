import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/media/cloudinary_image_service.dart';

/// Full-resolution profile image preview. The cover and avatar are separate:
/// tapping either opens its saved image, not an unrelated room background.
class ProfilePhotoViewer extends StatefulWidget {
  const ProfilePhotoViewer({
    required this.userId,
    this.cover = false,
    super.key,
  });

  final String userId;
  final bool cover;

  @override
  State<ProfilePhotoViewer> createState() => _ProfilePhotoViewerState();
}

class _ProfilePhotoViewerState extends State<ProfilePhotoViewer> {
  bool _busy = false;

  bool get _mine => FirebaseAuth.instance.currentUser?.uid == widget.userId;
  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  String get _field => widget.cover ? 'coverUrl' : 'photoUrl';

  Future<void> _changeImage() async {
    if (!_mine || _busy) return;
    try {
      final selected = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 93,
        maxWidth: widget.cover ? 2400 : 1600,
      );
      if (selected == null || !mounted) return;
      setState(() => _busy = true);
      final uploaded = await CloudinaryImageService.uploadImage(
        File(selected.path),
        folder: 'worldvoice/users/${widget.userId}/${widget.cover ? 'cover' : 'profile'}',
      );
      await FirebaseFirestore.instance.collection('users')
          .doc(widget.userId).update({
        _field: uploaded.url,
        (widget.cover ? 'coverPublicId' : 'photoPublicId'): uploaded.publicId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_ar ? 'تم تحديث الصورة' : 'Photo updated'),
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_ar ? 'تعذّر تغيير الصورة: $error' : 'Could not update photo: $error'),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _unavailableAi() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_ar ? 'إنشاء صورة بالذكاء الاصطناعي' : 'AI avatar generator'),
        content: Text(_ar
            ? 'هذه الميزة تتطلب ربط خدمة إنشاء صور فعلية. لم يتم تفعيلها بعد، ولن نغيّر صورتك أو نخصم أي كوينز.'
            : 'AI image generation needs a real image-generation service. It is not connected yet; no photo will be changed and no coins charged.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_ar ? 'حسنًا' : 'OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users')
            .doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          final photo = (snapshot.data?.data()?[_field] as String?)?.trim() ?? '';
          return SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IconButton(
                    key: const ValueKey('profile-photo-viewer-back'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white),
                    tooltip: _ar ? 'رجوع' : 'Back',
                  ),
                ),
                Expanded(
                  child: Center(
                    child: photo.isEmpty
                        ? Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(widget.cover
                                ? Icons.landscape_outlined
                                : Icons.person_rounded,
                              size: 92, color: Colors.white54),
                            const SizedBox(height: 12),
                            Text(_ar ? 'لم تُضف صورة بعد' : 'No photo yet',
                              style: const TextStyle(color: Colors.white70)),
                          ])
                        : InteractiveViewer(
                            key: const ValueKey('profile-photo-zoom'),
                            minScale: 1,
                            maxScale: 4,
                            child: Image.network(
                              photo,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.broken_image_outlined,
                                size: 76, color: Colors.white70,
                              ),
                              loadingBuilder: (_, child, progress) => progress == null
                                  ? child
                                  : const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFFD8B56B)),
                                    ),
                            ),
                          ),
                  ),
                ),
                if (_mine)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      children: [
                        if (!widget.cover) ...[
                          _action(
                            key: 'avatar-ai-action',
                            icon: Icons.auto_awesome_rounded,
                            label: _ar
                                ? 'إنشاء صورة بالذكاء الاصطناعي'
                                : 'Create AI avatar',
                            trailing: _ar ? 'قريبًا' : 'Coming soon',
                            onTap: _busy ? null : _unavailableAi,
                          ),
                          const SizedBox(height: 10),
                          _action(
                            key: 'avatar-effects-action',
                            icon: Icons.auto_fix_high_rounded,
                            label: _ar
                                ? 'تأثير الصورة الرمزية'
                                : 'Avatar photo effects',
                            onTap: _busy || photo.isEmpty
                                ? null
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ProfileAvatarEffectsScreen(
                                        userId: widget.userId,
                                        photoUrl: photo,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        _action(
                          key: 'avatar-change-action',
                          icon: Icons.edit_square,
                          label: widget.cover
                              ? (_ar ? 'تغيير صورة الغلاف' : 'Change cover photo')
                              : (_ar ? 'تغيير الصورة الرمزية' : 'Change avatar'),
                          onTap: _busy ? null : _changeImage,
                        ),
                        if (_busy) ...[
                          const SizedBox(height: 10),
                          const LinearProgressIndicator(color: Color(0xFFD8B56B)),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _action({
    required String key,
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    String? trailing,
  }) {
    return Material(
      color: const Color(0xFF202020),
      borderRadius: BorderRadius.circular(19),
      child: ListTile(
        key: ValueKey(key),
        enabled: onTap != null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
        onTap: onTap,
        leading: Icon(icon, color: Colors.white, size: 27),
        title: Text(label, style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.w600)),
        trailing: trailing == null
            ? const Icon(Icons.chevron_right_rounded, color: Colors.white70)
            : Text(trailing, style: const TextStyle(color: Color(0xFFD8B56B))),
      ),
    );
  }
}

/// Preview-only filters stay local. Only Save uploads a transformed image.
class ProfileAvatarEffectsScreen extends StatefulWidget {
  const ProfileAvatarEffectsScreen({
    required this.userId,
    required this.photoUrl,
    super.key,
  });

  final String userId;
  final String photoUrl;

  @override
  State<ProfileAvatarEffectsScreen> createState() => _ProfileAvatarEffectsScreenState();
}

class _ProfileAvatarEffectsScreenState extends State<ProfileAvatarEffectsScreen> {
  int _selected = 0;
  bool _saving = false;

  static const _namesAr = ['الأصلية', 'أبيض وأسود', 'دافئ'];
  static const _namesEn = ['Original', 'Mono', 'Warm'];

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  Future<void> _save() async {
    if (_saving || _selected == 0 ||
        FirebaseAuth.instance.currentUser?.uid != widget.userId) {
      return;
    }
    setState(() => _saving = true);
    File? tempFile;
    try {
      final uri = Uri.tryParse(widget.photoUrl);
      if (uri == null || uri.scheme != 'https' || !uri.hasAuthority ||
          uri.userInfo.isNotEmpty) {
        throw StateError('Invalid profile photo URL');
      }
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200 || response.bodyBytes.length > 12 * 1024 * 1024) {
        throw StateError('Could not download profile photo');
      }
      final changed = await compute(_processAvatarPhoto, <String, Object>{
        'bytes': response.bodyBytes,
        'filter': _selected,
      });
      final cacheDir = await getTemporaryDirectory();
      tempFile = File('${cacheDir.path}/worldvoice_avatar_${DateTime.now().microsecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(changed, flush: true);
      final uploaded = await CloudinaryImageService.uploadImage(
        tempFile,
        folder: 'worldvoice/users/${widget.userId}/profile',
      );
      await FirebaseFirestore.instance.collection('users')
          .doc(widget.userId).update({
        'photoUrl': uploaded.url,
        'photoPublicId': uploaded.publicId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_ar
            ? 'تعذّر حفظ التأثير: $error'
            : 'Could not save effect: $error'),
      ));
    } finally {
      if (tempFile != null) {
        try { await tempFile.delete(); } catch (_) { /* Best-effort cleanup. */ }
      }
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = _ar ? _namesAr : _namesEn;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_ar ? 'تأثير الصورة الرمزية' : 'Avatar effects'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: Center(
              child: ColorFiltered(
                colorFilter: avatarPhotoFilter(_selected),
                child: Image.network(widget.photoUrl,
                  key: const ValueKey('avatar-effect-preview'),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined, color: Colors.white),
                ),
              ),
            )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        key: ValueKey('avatar-filter-$i'),
                        label: Text(labels[i]),
                        selected: _selected == i,
                        onSelected: _saving ? null : (_) => setState(() => _selected = i),
                      ),
                    )),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('avatar-filter-save'),
                  onPressed: _saving || _selected == 0 ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check_rounded),
                  label: Text(_ar ? 'حفظ التأثير' : 'Save effect'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

ColorFilter avatarPhotoFilter(int effect) => switch (effect) {
  1 => const ColorFilter.matrix([
       0.2126, 0.7152, 0.0722, 0, 0,
       0.2126, 0.7152, 0.0722, 0, 0,
       0.2126, 0.7152, 0.0722, 0, 0,
       0, 0, 0, 1, 0,
     ]),
  2 => const ColorFilter.matrix([
       0.393, 0.769, 0.189, 0, 0,
       0.349, 0.686, 0.168, 0, 0,
       0.272, 0.534, 0.131, 0, 0,
       0, 0, 0, 1, 0,
     ]),
  _ => const ColorFilter.mode(Colors.transparent, BlendMode.dst),
};

Uint8List _processAvatarPhoto(Map<String, Object> args) {
  final bytes = args['bytes']! as Uint8List;
  final effect = args['filter']! as int;
  final source = img.decodeImage(bytes);
  if (source == null) throw StateError('Unsupported profile photo');
  final scaled = source.width > 1200 || source.height > 1200
      ? img.copyResize(source, width: source.width >= source.height ? 1200 : null,
          height: source.height > source.width ? 1200 : null)
      : source;
  final result = switch (effect) {
    1 => img.grayscale(scaled),
    2 => img.sepia(scaled),
    _ => scaled,
  };
  return Uint8List.fromList(img.encodeJpg(result, quality: 91));
}
