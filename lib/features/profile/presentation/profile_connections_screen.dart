import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import '../services/profile_social_service.dart';
import 'public_profile_screen.dart';

enum ProfileConnectionType { followers, following, partners }

class ProfileConnectionsScreen extends StatelessWidget {
  const ProfileConnectionsScreen({
    required this.type,
    required this.localeController,
    super.key,
  });

  final ProfileConnectionType type;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final code = localeController.locale?.languageCode ?? 'en';

    if (uid == null) {
      return const Scaffold(body: Center(child: Text('No signed-in user')));
    }

    final title = switch (type) {
      ProfileConnectionType.followers =>
        _t(code, 'Followers', 'المتابعون', 'Seguidores'),
      ProfileConnectionType.following =>
        _t(code, 'Following', 'يتابع', 'Siguiendo'),
      ProfileConnectionType.partners =>
        _t(code, 'Partners', 'Partner', 'Partners'),
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: type == ProfileConnectionType.partners
          ? _PartnersList(
              uid: uid,
              code: code,
              localeController: localeController,
            )
          : _ConnectionList(
              stream: type == ProfileConnectionType.followers
                  ? ProfileSocialService.followers(uid)
                  : ProfileSocialService.following(uid),
              code: code,
              localeController: localeController,
            ),
    );
  }
}

class _ConnectionList extends StatelessWidget {
  const _ConnectionList({
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return _EmptyConnections(code: code);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) => _PersonTile(
            userId: docs[index].id,
            fallback: docs[index].data(),
            localeController: localeController,
          ),
        );
      },
    );
  }
}

class _PartnersList extends StatelessWidget {
  const _PartnersList({
    required this.uid,
    required this.code,
    required this.localeController,
  });

  final String uid;
  final String code;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Set<String>>(
      future: ProfileSocialService.mutualPartnerIds(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final ids = snapshot.data!.toList();
        if (ids.isEmpty) {
          return _EmptyConnections(
            code: code,
            partners: true,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: ids.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) => _PersonTile(
            userId: ids[index],
            fallback: const <String, dynamic>{},
            localeController: localeController,
          ),
        );
      },
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({
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
          subtitle: username?.isNotEmpty == true ? Text('@' + username!) : null,
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

class _EmptyConnections extends StatelessWidget {
  const _EmptyConnections({
    required this.code,
    this.partners = false,
  });

  final String code;
  final bool partners;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          partners
              ? _t(
                  code,
                  'Partners appear when you follow each other.',
                  'يظهر الـPartner عندما تتابعان بعضكما.',
                  'Los Partners aparecen cuando se siguen mutuamente.',
                )
              : _t(
                  code,
                  'No people here yet.',
                  'لا يوجد أشخاص هنا حتى الآن.',
                  'Todavía no hay personas aquí.',
                ),
          textAlign: TextAlign.center,
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
