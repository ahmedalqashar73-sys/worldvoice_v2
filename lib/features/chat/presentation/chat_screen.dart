import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({required this.localeController, super.key});
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final code = localeController.locale?.languageCode ?? 'en';
    final rtl = const {'ar','ur','fa'}.contains(code);
    final title = code == 'ar' ? 'الدردشة' : code == 'es' ? 'Chat' : 'Chat';
    final search = code == 'ar' ? 'ابحث في الرسائل' : code == 'es' ? 'Buscar mensajes' : 'Search messages';

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Row(
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const Spacer(),
                IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.edit_square)),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              decoration: InputDecoration(
                hintText: search,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _ChatRow(name: 'Manar', flag: '🇺🇸', message: 'Let’s practice English today', time: '16:05', unread: 2),
            const _ChatRow(name: 'Nada', flag: '🇮🇶', message: 'مرحبا 👋', time: '15:08'),
            const _ChatRow(name: 'Sam', flag: '🇾🇪', message: 'Voice room?', time: 'Yesterday'),
            const _ChatRow(name: 'WorldVoice AI', flag: '✨', message: 'Your lesson is ready', time: 'Yesterday', ai: true),
          ],
        ),
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({
    required this.name,
    required this.flag,
    required this.message,
    required this.time,
    this.unread = 0,
    this.ai = false,
  });

  final String name;
  final String flag;
  final String message;
  final String time;
  final int unread;
  final bool ai;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 7),
      leading: CircleAvatar(
        radius: 29,
        backgroundColor: ai ? cs.primaryContainer : cs.surfaceContainerHighest,
        child: Text(flag, style: const TextStyle(fontSize: 25)),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: Theme.of(context).textTheme.bodySmall),
          if (unread > 0) ...[
            const SizedBox(height: 5),
            CircleAvatar(
              radius: 10,
              backgroundColor: cs.primary,
              child: Text('$unread', style: TextStyle(fontSize: 10, color: cs.onPrimary)),
            ),
          ],
        ],
      ),
    );
  }
}
