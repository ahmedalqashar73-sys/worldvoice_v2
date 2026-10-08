import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../chat/presentation/incoming_call_watcher.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../profile/presentation/public_profile_screen.dart';
import '../../profile/presentation/profile_form_validation.dart';
import '../../profile/presentation/user_profile_screen.dart';
import '../../rooms/presentation/rooms_hub_screen.dart';
import 'home_feed_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.localeController, super.key});

  final LocaleController localeController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final code = widget.localeController.locale?.languageCode ?? 'en';
    final rtl = const {'ar', 'ur', 'fa'}.contains(code);
    final labels = _MainNavLabels(code);

    final pages = <Widget>[
      _HomeLanding(
        localeController: widget.localeController,
      ),
      DiscoverScreen(localeController: widget.localeController),
      RoomsHubScreen(localeController: widget.localeController),
      ChatScreen(localeController: widget.localeController),
      UserProfileScreen(localeController: widget.localeController),
    ];

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: IncomingCallWatcher(
        child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) {
            setState(() => _index = value);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: labels.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.explore_outlined),
              selectedIcon: const Icon(Icons.explore_rounded),
              label: labels.discover,
            ),
            NavigationDestination(
              icon: const Icon(Icons.mic_none_rounded),
              selectedIcon: const Icon(Icons.mic_rounded),
              label: labels.rooms,
            ),
            NavigationDestination(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: const Icon(Icons.chat_bubble_rounded),
              label: labels.chat,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded),
              label: labels.profile,
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _HomeLanding extends StatefulWidget {
  const _HomeLanding({
    required this.localeController,
  });

  final LocaleController localeController;

  @override
  State<_HomeLanding> createState() => _HomeLandingState();
}

class _HomeLandingState extends State<_HomeLanding> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _searching = false;
  String? _searchError;
  List<_HomeUserSearchResult> _results = const [];
  final GlobalKey<HomeFeedSectionState> _feedKey =
      GlobalKey<HomeFeedSectionState>();

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final normalized = ProfileFormValidation.normalizeUsername(value);
    if (normalized.isEmpty) {
      setState(() {
        _searching = false;
        _searchError = null;
        _results = const [];
      });
      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: 280),
      () => _searchByUsername(normalized),
    );
  }

  Future<void> _searchByUsername(String normalized) async {
    if (!mounted) return;

    if (!ProfileFormValidation.isValidUsername(normalized)) {
      setState(() {
        _searching = false;
        _searchError = _isArabic
            ? 'اكتب اليوزرنيم بحروف إنجليزية أو أرقام أو _.'
            : 'Use letters, numbers, or _ in the username.';
        _results = const [];
      });
      return;
    }

    setState(() {
      _searching = true;
      _searchError = null;
    });

    try {
      final handles = await FirebaseFirestore.instance
          .collection('usernames')
          .orderBy(FieldPath.documentId)
          .startAt(<Object>[normalized])
          .endAt(<Object>['$normalized\uf8ff'])
          .limit(12)
          .get();

      final profileSnapshots = await Future.wait(
        handles.docs.map((handle) async {
          final uid = (handle.data()['uid'] ?? '').toString().trim();
          if (uid.isEmpty) return null;
          final user = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          if (!user.exists) return null;

          final data = user.data() ?? const <String, dynamic>{};
          return _HomeUserSearchResult(
            uid: uid,
            username: (data['username'] ?? handle.id).toString(),
            displayName:
                (data['displayName'] ?? data['name'] ?? handle.id).toString(),
            photoUrl: (data['photoUrl'] ?? '').toString(),
            country: (data['country'] ?? '').toString(),
            isOnline: data['isOnline'] == true,
          );
        }),
      );

      if (!mounted ||
          ProfileFormValidation.normalizeUsername(_searchController.text) !=
              normalized) {
        return;
      }

      setState(() {
        _searching = false;
        _results = profileSnapshots
            .whereType<_HomeUserSearchResult>()
            .toList(growable: false);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchError = _isArabic
            ? 'تعذر البحث الآن. حاول مرة ثانية.'
            : 'Search is unavailable right now. Try again.';
        _results = const [];
      });
    }
  }

  bool get _isArabic {
    final code = widget.localeController.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'ar';
  }

  void _openProfile(_HomeUserSearchResult user) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicProfileScreen(
          userId: user.uid,
          localeController: widget.localeController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.localeController.locale?.languageCode ?? 'en';
    final t = _HomeLabels(code);
    final ar = code == 'ar';

    return SafeArea(
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(top: 8, bottom: 28),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _feedKey.currentState?.createPost(),
                    tooltip: t.createPost,
                    icon: const Icon(Icons.add_box_outlined, size: 27),
                  ),
                  IconButton(
                    onPressed: () {},
                    tooltip: t.notifications,
                    icon: const Icon(Icons.notifications_none_rounded, size: 27),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SearchBar(
            controller: _searchController,
            hintText: ar
                ? 'ابحث باليوزرنيم @username'
                : 'Search by username @username',
            leading: const Icon(Icons.search_rounded),
            trailing: [
              if (_searching)
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_searchController.text.isNotEmpty)
                IconButton(
                  tooltip: ar ? 'مسح البحث' : 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
            onChanged: (value) {
              setState(() {});
              _onSearchChanged(value);
            },
              onSubmitted: (value) => _searchByUsername(
                ProfileFormValidation.normalizeUsername(value),
              ),
            ),
          ),
          if (_searchError != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                _searchError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (_searchController.text.trim().isNotEmpty &&
              !_searching &&
              _searchError == null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        ar ? 'لا يوجد مستخدم بهذا اليوزرنيم.' : 'No users found.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          for (var index = 0;
                              index < _results.length;
                              index++) ...[
                            _HomeUserSearchTile(
                              user: _results[index],
                              onTap: () => _openProfile(_results[index]),
                            ),
                            if (index != _results.length - 1)
                              const Divider(height: 1, indent: 70),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
          const SizedBox(height: 10),
          HomeFeedSection(
            key: _feedKey,
            localeController: widget.localeController,
          ),
        ],
      ),
    );
  }
}

class _HomeUserSearchResult {
  const _HomeUserSearchResult({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.photoUrl,
    required this.country,
    required this.isOnline,
  });

  final String uid;
  final String username;
  final String displayName;
  final String photoUrl;
  final String country;
  final bool isOnline;
}

class _HomeUserSearchTile extends StatelessWidget {
  const _HomeUserSearchTile({
    required this.user,
    required this.onTap,
  });

  final _HomeUserSearchResult user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photo = user.photoUrl.trim();
    final username = ProfileFormValidation.normalizeUsername(user.username);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: photo.isEmpty ? null : NetworkImage(photo),
            child: photo.isEmpty
                ? const Icon(Icons.person_rounded)
                : null,
          ),
          if (user.isOnline)
            PositionedDirectional(
              end: -1,
              bottom: 1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        user.displayName.trim().isEmpty ? '@$username' : user.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        user.country.trim().isEmpty
            ? '@$username'
            : '@$username • ${user.country}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _MainNavLabels {
  _MainNavLabels(String code)
      : home = code == 'ar'
            ? 'الرئيسية'
            : code == 'es'
                ? 'Inicio'
                : 'Home',
        discover = code == 'ar'
            ? 'اكتشف'
            : code == 'es'
                ? 'Descubrir'
                : 'Discover',
        rooms = code == 'ar'
            ? 'Rooms'
            : code == 'es'
                ? 'Rooms'
                : 'Rooms',
        chat = code == 'ar'
            ? 'الدردشة'
            : code == 'es'
                ? 'Chat'
                : 'Chat',
        profile = code == 'ar'
            ? 'البروفايل'
            : code == 'es'
                ? 'Perfil'
                : 'Profile';

  final String home;
  final String discover;
  final String rooms;
  final String chat;
  final String profile;
}

class _HomeLabels {
  _HomeLabels(String code)
      : notifications = code == 'ar'
            ? 'الإشعارات'
            : code == 'es'
                ? 'Notificaciones'
                : 'Notifications',
        createPost = code == 'ar'
            ? 'إنشاء منشور'
            : code == 'es'
                ? 'Crear publicación'
                : 'Create post';

  final String notifications;
  final String createPost;
}
