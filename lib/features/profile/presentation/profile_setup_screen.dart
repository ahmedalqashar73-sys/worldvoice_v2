import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({required this.localeController, super.key});
  final LocaleController localeController;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final name = TextEditingController();
  final username = TextEditingController();
  final bio = TextEditingController();
  bool? usernameAvailable;
  bool saving = false;

  String get normalizedUsername =>
      username.text.trim().toLowerCase().replaceFirst('@', '');

  Future<void> checkUsername() async {
    final value = normalizedUsername;
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(value)) {
      setState(() => usernameAvailable = false);
      return;
    }
    final doc =
        await FirebaseFirestore.instance.collection('usernames').doc(value).get();
    if (mounted) {
      setState(() => usernameAvailable = !doc.exists ||
          doc.data()?['uid'] == FirebaseAuth.instance.currentUser?.uid);
    }
  }

  Future<void> saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || name.text.trim().isEmpty || usernameAvailable != true) {
      return;
    }
    setState(() => saving = true);
    final db = FirebaseFirestore.instance;
    try {
      await db.runTransaction((tx) async {
        final handle = db.collection('usernames').doc(normalizedUsername);
        final existing = await tx.get(handle);
        if (existing.exists && existing.data()?['uid'] != user.uid) {
          throw StateError('username-taken');
        }
        tx.set(handle, {
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.set(db.collection('users').doc(user.uid), {
          'uid': user.uid,
          'email': user.email,
          'displayName': name.text.trim(),
          'username': normalizedUsername,
          'bio': bio.text.trim(),
          'profileCompleted': true,
          'followersCount': 0,
          'followingCount': 0,
          'isVip': false,
          'isPartner': false,
          'isVerified': false,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Color(0xFF159B62),
          content: Text('تم حفظ البروفايل بنجاح ✓',
              style: TextStyle(color: Colors.white)),
        ));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    username.dispose();
    bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = const {'ar', 'ur', 'fa'}
        .contains(widget.localeController.locale?.languageCode);
    final scheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text(rtl ? 'أنشئ هويتك في WorldVoice' : 'Create your WorldVoice identity',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              Center(child: Container(
                width: 124, height: 124,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [scheme.primary, scheme.tertiary])),
                padding: const EdgeInsets.all(4),
                child: CircleAvatar(backgroundColor: scheme.surfaceContainerHighest, child: const Icon(Icons.person_rounded, size: 62)),
              )),
              const SizedBox(height: 28),
              _Field(controller: name, label: rtl ? 'الاسم' : 'Name', icon: Icons.badge_outlined),
              const SizedBox(height: 14),
              TextField(
                controller: username,
                textDirection: TextDirection.ltr,
                onChanged: (_) => setState(() => usernameAvailable = null),
                decoration: InputDecoration(
                  labelText: rtl ? 'اسم المستخدم الفريد' : 'Unique username',
                  hintText: '@username',
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  suffixIcon: IconButton(
                    onPressed: checkUsername,
                    icon: Icon(
                      usernameAvailable == true ? Icons.check_circle_rounded :
                      usernameAvailable == false ? Icons.cancel_rounded : Icons.search_rounded,
                      color: usernameAvailable == true ? Colors.green : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(rtl ? '3–20 حرفًا: إنجليزي، أرقام و _. لا يمكن تكراره.' : '3–20 characters: letters, numbers and _. Must be unique.'),
              const SizedBox(height: 18),
              _Field(controller: bio, label: rtl ? 'نبذة عنك' : 'About you', icon: Icons.auto_awesome_rounded, maxLines: 3),
              const SizedBox(height: 22),
              _PremiumTile(icon: Icons.mic_rounded, title: rtl ? 'التعريف الصوتي' : 'Voice introduction', subtitle: rtl ? 'عرّف عن نفسك بصوتك' : 'Introduce yourself with your voice'),
              _PremiumTile(icon: Icons.language_rounded, title: rtl ? 'اللغات والمستوى' : 'Languages & level', subtitle: rtl ? 'لغتك الأم واللغات التي تتعلمها' : 'Native and learning languages'),
              _PremiumTile(icon: Icons.public_rounded, title: rtl ? 'الدولة والمدينة' : 'Country & city', subtitle: rtl ? 'مع تحكم كامل بالخصوصية' : 'With full privacy control'),
              _PremiumTile(icon: Icons.favorite_outline_rounded, title: rtl ? 'الهوايات والاهتمامات' : 'Interests & hobbies', subtitle: rtl ? 'للمطابقة اللغوية الذكية' : 'For smarter matching'),
              _PremiumTile(icon: Icons.track_changes_rounded, title: rtl ? 'أهداف التعلم' : 'Learning goals', subtitle: rtl ? 'حدد ما تريد تحقيقه' : 'Define what you want to achieve'),
              _PremiumTile(icon: Icons.work_outline_rounded, title: rtl ? 'المهنة والسفر' : 'Work & travel', subtitle: rtl ? 'شارك المزيد عن عالمك' : 'Share more about your world'),
              const SizedBox(height: 24),
              SizedBox(
                height: 58,
                child: FilledButton.icon(
                  onPressed: saving ? null : saveProfile,
                  icon: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.rocket_launch_rounded),
                  label: Text(rtl ? 'إطلاق بروفايلي' : 'Launch my profile',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label, required this.icon, this.maxLines = 1});
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      );
}

class _PremiumTile extends StatelessWidget {
  const _PremiumTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 11),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          leading: CircleAvatar(child: Icon(icon)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      );
}
