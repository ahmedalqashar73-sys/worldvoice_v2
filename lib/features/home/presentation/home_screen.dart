import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../learn/presentation/learn_screen.dart';
import '../../live/presentation/live_screen.dart';
import '../../profile/presentation/user_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.localeController, super.key});
  final LocaleController localeController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          localeController: widget.localeController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.localeController.locale?.languageCode ?? 'en';
    final rtl = const {'ar','ur','fa'}.contains(code);
    final labels = _labels(code);

    final pages = <Widget>[
      _HomeLanding(
        localeController: widget.localeController,
        onProfile: _openProfile,
        onLive: () => setState(() => index = 1),
        onLearn: () => setState(() => index = 2),
        onChat: () => setState(() => index = 3),
      ),
      LiveScreen(
        localeController: widget.localeController,
        onOpenLearn: () => setState(() => index = 2),
      ),
      LearnScreen(localeController: widget.localeController),
      ChatScreen(localeController: widget.localeController),
      DiscoverScreen(localeController: widget.localeController),
    ];

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: IndexedStack(index: index, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: labels.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.graphic_eq_outlined),
              selectedIcon: const Icon(Icons.graphic_eq_rounded),
              label: labels.live,
            ),
            NavigationDestination(
              icon: const Icon(Icons.school_outlined),
              selectedIcon: const Icon(Icons.school_rounded),
              label: labels.learn,
            ),
            NavigationDestination(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: const Icon(Icons.chat_bubble_rounded),
              label: labels.chat,
            ),
            NavigationDestination(
              icon: const Icon(Icons.explore_outlined),
              selectedIcon: const Icon(Icons.explore_rounded),
              label: labels.discover,
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
    required this.onProfile,
    required this.onLive,
    required this.onLearn,
    required this.onChat,
  });

  final LocaleController localeController;
  final VoidCallback onProfile;
  final VoidCallback onLive;
  final VoidCallback onLearn;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final code = localeController.locale?.languageCode ?? 'en';
    final t = _HomeLabels(code);
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
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
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onProfile,
                tooltip: t.profile,
                icon: const Icon(Icons.person_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF086A4B), Color(0xFF6045C9)],
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
                const Icon(
                  Icons.public_rounded,
                  size: 66,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            t.quick,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _HomeAction(
                icon: Icons.mic_rounded,
                title: t.voiceRooms,
                subtitle: t.voiceRoomsBody,
                onTap: onLive,
              ),
              _HomeAction(
                icon: Icons.live_tv_rounded,
                title: t.live,
                subtitle: t.liveBody,
                onTap: onLive,
              ),
              _HomeAction(
                icon: Icons.smart_toy_rounded,
                title: t.ai,
                subtitle: t.aiBody,
                onTap: onLive,
              ),
              _HomeAction(
                icon: Icons.school_rounded,
                title: t.learn,
                subtitle: t.learnBody,
                onTap: onLearn,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: cs.primaryContainer,
                child: Icon(Icons.chat_bubble_rounded, color: cs.primary),
              ),
              title: Text(
                t.messages,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(t.messagesBody),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 17),
              onTap: onChat,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
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
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Icon(icon, color: cs.primary),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

({
  String home,
  String live,
  String learn,
  String chat,
  String discover,
}) _labels(String code) {
  if (code == 'ar') {
    return (
      home: 'الرئيسية',
      live: 'اللايف',
      learn: 'تعلّم',
      chat: 'الدردشة',
      discover: 'اكتشف',
    );
  }
  if (code == 'es') {
    return (
      home: 'Inicio',
      live: 'En vivo',
      learn: 'Aprender',
      chat: 'Chat',
      discover: 'Descubrir',
    );
  }
  return (
    home: 'Home',
    live: 'Live',
    learn: 'Learn',
    chat: 'Chat',
    discover: 'Discover',
  );
}

class _HomeLabels {
  _HomeLabels(String code)
      : profile = code == 'ar' ? 'البروفايل' : code == 'es' ? 'Perfil' : 'Profile',
        welcome = code == 'ar' ? 'تعلّم. تكلّم. تواصل.' : code == 'es' ? 'Aprende. Habla. Conecta.' : 'Learn. Speak. Connect.',
        subtitle = code == 'ar' ? 'كل عالم WorldVoice من مكان واحد.' : code == 'es' ? 'Todo WorldVoice en un solo lugar.' : 'Your WorldVoice world in one place.',
        quick = code == 'ar' ? 'ابدأ الآن' : code == 'es' ? 'Empieza ahora' : 'Start now',
        voiceRooms = code == 'ar' ? 'الغرف الصوتية' : code == 'es' ? 'Salas de voz' : 'Voice rooms',
        voiceRoomsBody = code == 'ar' ? 'ادخل وتحدث مباشرة' : code == 'es' ? 'Entra y habla en directo' : 'Join and speak live',
        live = code == 'ar' ? 'بث مباشر' : code == 'es' ? 'Directo' : 'Live',
        liveBody = code == 'ar' ? 'اكتشف بثوث العالم' : code == 'es' ? 'Descubre directos' : 'Discover global live',
        ai = code == 'ar' ? 'المعلم AI' : code == 'es' ? 'Profesor AI' : 'AI Teacher',
        aiBody = code == 'ar' ? 'محادثة وترجمة وكويز' : code == 'es' ? 'Habla, traduce y practica' : 'Speak, translate & quiz',
        learn = code == 'ar' ? 'تعلّم' : code == 'es' ? 'Aprender' : 'Learn',
        learnBody = code == 'ar' ? 'شركاء ودورات وممارسة' : code == 'es' ? 'Compañeros y cursos' : 'Partners and courses',
        messages = code == 'ar' ? 'الرسائل' : code == 'es' ? 'Mensajes' : 'Messages',
        messagesBody = code == 'ar' ? 'الشات منفصل ومنظم.' : code == 'es' ? 'Chat separado y organizado.' : 'A separate, organized chat area.';

  final String profile;
  final String welcome;
  final String subtitle;
  final String quick;
  final String voiceRooms;
  final String voiceRoomsBody;
  final String live;
  final String liveBody;
  final String ai;
  final String aiBody;
  final String learn;
  final String learnBody;
  final String messages;
  final String messagesBody;
}
