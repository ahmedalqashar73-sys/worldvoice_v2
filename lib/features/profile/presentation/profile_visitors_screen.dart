import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';

import '../../../core/localization/locale_controller.dart';
import '../services/profile_social_service.dart';
import 'public_profile_screen.dart';

class ProfileVisitorsScreen extends StatelessWidget {
  const ProfileVisitorsScreen({
    required this.localeController,
    required this.isVip,
    super.key,
  });

  final LocaleController localeController;
  final bool isVip;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final code = localeController.locale?.languageCode ?? 'en';

    if (uid == null) {
      return const Scaffold(body: Center(child: Text('No signed-in user')));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.of(code).profile('visitors')),
          bottom: TabBar(
            tabs: [
              Tab(
                text: AppStrings.of(code).profile('iVisited'),
              ),
              Tab(
                text: AppStrings.of(code).profile('visitedMe'),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _VisitList(
              stream: ProfileSocialService.visitedProfiles(uid),
              code: code,
              localeController: localeController,
            ),
            isVip
                ? _VisitList(
                    stream: ProfileSocialService.visitors(uid),
                    code: code,
                    localeController: localeController,
                  )
                : _LockedVisitors(code: code),
          ],
        ),
      ),
    );
  }
}

class _LockedVisitors extends StatelessWidget {
  const _LockedVisitors({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility_off_rounded, size: 52),
                const SizedBox(height: 14),
                Text(
                  AppStrings.of(code).profile('seeWhoVisited'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.of(code).profile('visitorsVipOrAd'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('My VIP'),
                        content: Text(
                          AppStrings.of(code).profile('vipUnlockVisitors'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              AppStrings.of(code).profile('ok'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.workspace_premium_rounded),
                  label: const Text('My VIP'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.ondemand_video_rounded),
                  label: Text(
                    AppStrings.of(code).profile('watchAdComingSoon'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VisitList extends StatelessWidget {
  const _VisitList({
    required this.stream,
    required this.code,
    required this.localeController,
  });

  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String code;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              AppStrings.of(code).profile('visitsLoadFailed'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text(
              AppStrings.of(code).profile('noVisits'),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = docs[index];
            return _VisitTile(
              userId: doc.id,
              fallback: doc.data(),
              localeController: localeController,
            );
          },
        );
      },
    );
  }
}

class _VisitTile extends StatelessWidget {
  const _VisitTile({
    required this.userId,
    required this.fallback,
    required this.localeController,
  });

  final String userId;
  final Map<String, dynamic> fallback;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? fallback;
        final name = (data['displayName'] as String?)?.trim();
        final username = (data['username'] as String?)?.trim();
        final photo = data['photoUrl'] as String?;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          leading: CircleAvatar(
            radius: 26,
            backgroundImage:
                photo == null || photo.isEmpty ? null : NetworkImage(photo),
            child: photo == null || photo.isEmpty
                ? const Icon(Icons.person_rounded)
                : null,
          ),
          title: Text(
            name?.isNotEmpty == true ? name! : 'WorldVoice',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: username?.isNotEmpty == true ? Text('@\${username!}') : null,
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PublicProfileScreen(
                  userId: userId,
                  localeController: localeController,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

