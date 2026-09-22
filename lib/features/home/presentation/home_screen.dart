import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../profile/presentation/user_profile_screen.dart';
import '../../rooms/presentation/rooms_hub_screen.dart';

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
        onOpenRooms: () => setState(() => _index = 2),
        onOpenDiscover: () => setState(() => _index = 1),
        onOpenChat: () => setState(() => _index = 3),
      ),
      DiscoverScreen(localeController: widget.localeController),
      RoomsHubScreen(localeController: widget.localeController),
      ChatScreen(localeController: widget.localeController),
      UserProfileScreen(localeController: widget.localeController),
    ];

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
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
    );
  }
}

class _HomeLanding extends StatelessWidget {
  const _HomeLanding({
    required this.localeController,
    required this.onOpenRooms,
    required this.onOpenDiscover,
    required this.onOpenChat,
  });

  final LocaleController localeController;
  final VoidCallback onOpenRooms;
  final VoidCallback onOpenDiscover;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final code = localeController.locale?.languageCode ?? 'en';
    final t = _HomeLabels(code);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'WorldVoice',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () {},
                tooltip: t.notifications,
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [Color(0xFF0B7656), Color(0xFF5F46CA)],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.welcome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.public_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            t.startHere,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          _HomeShortcut(
            icon: Icons.mic_rounded,
            title: t.rooms,
            subtitle: t.roomsBody,
            onTap: onOpenRooms,
          ),
          _HomeShortcut(
            icon: Icons.explore_rounded,
            title: t.discover,
            subtitle: t.discoverBody,
            onTap: onOpenDiscover,
          ),
          _HomeShortcut(
            icon: Icons.chat_bubble_rounded,
            title: t.chat,
            subtitle: t.chatBody,
            onTap: onOpenChat,
          ),
        ],
      ),
    );
  }
}

class _HomeShortcut extends StatelessWidget {
  const _HomeShortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 27,
          backgroundColor: colors.primaryContainer,
          child: Icon(icon, color: colors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
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
        welcome = code == 'ar'
            ? 'تعلّم. تكلّم. تواصل.'
            : code == 'es'
                ? 'Aprende. Habla. Conecta.'
                : 'Learn. Speak. Connect.',
        subtitle = code == 'ar'
            ? 'كل ما تحتاجه في WorldVoice من واجهة بسيطة ونظيفة.'
            : code == 'es'
                ? 'Todo WorldVoice desde una interfaz simple y limpia.'
                : 'Everything in WorldVoice from one clean home.',
        startHere = code == 'ar'
            ? 'ابدأ من هنا'
            : code == 'es'
                ? 'Empieza aquí'
                : 'Start here',
        rooms = code == 'ar'
            ? 'Rooms'
            : code == 'es'
                ? 'Rooms'
                : 'Rooms',
        roomsBody = code == 'ar'
            ? 'ChatGPT AI، Live، Learn، والغرف الصوتية.'
            : code == 'es'
                ? 'ChatGPT AI, Live, Learn y salas de voz.'
                : 'ChatGPT AI, Live, Learn, and Voice Rooms.',
        discover = code == 'ar'
            ? 'اكتشف'
            : code == 'es'
                ? 'Descubrir'
                : 'Discover',
        discoverBody = code == 'ar'
            ? 'اكتشف أشخاصًا وقصصًا ومحتوى جديدًا.'
            : code == 'es'
                ? 'Descubre personas, historias y contenido.'
                : 'Discover people, stories, and new content.',
        chat = code == 'ar'
            ? 'الدردشة'
            : code == 'es'
                ? 'Chat'
                : 'Chat',
        chatBody = code == 'ar'
            ? 'كل رسائلك ومحادثاتك في مكان واحد.'
            : code == 'es'
                ? 'Todos tus mensajes en un solo lugar.'
                : 'All your messages in one place.';

  final String notifications;
  final String welcome;
  final String subtitle;
  final String startHere;
  final String rooms;
  final String roomsBody;
  final String discover;
  final String discoverBody;
  final String chat;
  final String chatBody;
}
