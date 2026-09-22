import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({required this.localeController, super.key});
  final LocaleController localeController;

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final _search = TextEditingController();
  int filter = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.localeController.locale?.languageCode ?? 'en';
    final rtl = const {'ar','ur','fa'}.contains(code);
    final t = _LearnLabels(code);

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded, size: 28),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB000), Color(0xFFFFD54F)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'VIP',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C1C63), Color(0xFF3C2586)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Color(0xFF7457FF),
                    child: Icon(Icons.notifications_active_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.bannerTitle,
                          style: const TextStyle(
                            color: Color(0xFF9C7CFF),
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          t.bannerBody,
                          style: const TextStyle(color: Color(0xFFB8A9E8)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.close_rounded, color: Color(0xFF8569F5)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 112,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _Tool(icon: Icons.menu_book_rounded, label: t.courses),
                  _Tool(icon: Icons.auto_awesome_rounded, label: t.practice),
                  _Tool(icon: Icons.translate_rounded, label: t.translate),
                  _Tool(icon: Icons.smart_toy_rounded, label: t.aiTeacher),
                  _Tool(icon: Icons.keyboard_arrow_down_rounded, label: t.more),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: t.search,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: t.filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ChoiceChip(
                  selected: filter == i,
                  label: Text(t.filters[i]),
                  onSelected: (_) => setState(() => filter = i),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.section,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            ...const [
              _PartnerTile(
                name: 'Manar',
                flag: '🇺🇸',
                language: 'English',
                status: 'I’ll be back later',
                badge: 'Voice',
              ),
              _PartnerTile(
                name: 'Nada',
                flag: '🇮🇶',
                language: 'Arabic',
                status: 'Available to practice',
                badge: 'Online',
              ),
              _PartnerTile(
                name: 'Sam',
                flag: '🇾🇪',
                language: 'Arabic • English',
                status: 'Voice room',
                badge: 'Voice',
              ),
              _PartnerTile(
                name: 'Abdullah Omer',
                flag: '🇸🇦',
                language: 'Arabic • English',
                status: 'Language exchange',
                badge: 'VIP',
                vip: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 94,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(icon, size: 30, color: cs.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PartnerTile extends StatelessWidget {
  const _PartnerTile({
    required this.name,
    required this.flag,
    required this.language,
    required this.status,
    required this.badge,
    this.vip = false,
  });

  final String name;
  final String flag;
  final String language;
  final String status;
  final String badge;
  final bool vip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: .35)),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: cs.primaryContainer,
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (vip) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB000),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Text(
                          'VIP',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(flag),
                  ],
                ),
                const SizedBox(height: 4),
                Text(language, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(status, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(badge, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _LearnLabels {
  _LearnLabels(String code)
      : title = code == 'ar' ? 'المحادثات اللغوية' : code == 'es' ? 'Conversaciones de idiomas' : 'Language conversations',
        bannerTitle = code == 'ar' ? 'تنبيهات رسائل جديدة' : code == 'es' ? 'Avisos de mensajes nuevos' : 'New message alerts',
        bannerBody = code == 'ar' ? 'فعّل الإشعارات ولا تفوّت أي رسالة.' : code == 'es' ? 'Activa las notificaciones y no pierdas ningún mensaje.' : 'Turn on notifications and never miss a message.',
        courses = code == 'ar' ? 'كل الدورات' : code == 'es' ? 'Cursos' : 'Courses',
        practice = code == 'ar' ? 'تدريب' : code == 'es' ? 'Práctica' : 'Practice',
        translate = code == 'ar' ? 'مساعد الترجمة' : code == 'es' ? 'Traductor' : 'Translator',
        aiTeacher = code == 'ar' ? 'المعلم AI' : code == 'es' ? 'Profesor AI' : 'AI Teacher',
        more = code == 'ar' ? 'المزيد' : code == 'es' ? 'Más' : 'More',
        search = code == 'ar' ? 'بحث' : code == 'es' ? 'Buscar' : 'Search',
        section = code == 'ar' ? 'شركاء اللغة والغرف' : code == 'es' ? 'Compañeros y salas' : 'Partners & rooms',
        filters = code == 'ar'
            ? const ['الكل','أرشيف','متاح','غير مقروء','دوري']
            : code == 'es'
                ? const ['Todo','Archivo','Disponible','No leído','Cerca']
                : const ['All','Archive','Available','Unread','Nearby'];

  final String title;
  final String bannerTitle;
  final String bannerBody;
  final String courses;
  final String practice;
  final String translate;
  final String aiTeacher;
  final String more;
  final String search;
  final String section;
  final List<String> filters;
}
