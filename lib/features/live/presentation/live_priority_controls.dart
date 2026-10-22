import 'package:flutter/material.dart';

/// Live-only buttons rendered as the *last* children in the screen Stack.
/// Unlike controls nested below Agora video/platform surfaces, these remain
/// above captions, gift effects and camera preview hit-test regions.
class LivePriorityMenuButtons extends StatelessWidget {
  const LivePriorityMenuButtons({
    required this.ar,
    required this.onLanguage,
    required this.onOptions,
    super.key,
  });

  final bool ar;
  final VoidCallback onLanguage;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          key: const ValueKey('live-priority-language'),
          tooltip: ar ? 'الترجمة والـ AI' : 'Language and AI tools',
          onPressed: onLanguage,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xE31A4937),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.language_rounded),
        ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          key: const ValueKey('live-priority-options'),
          tooltip: ar ? 'مشاركة وخيارات اللايف' : 'Share and Live options',
          onPressed: onOptions,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xE31A4937),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.more_horiz_rounded),
        ),
      ],
    ),
  );
}

class LivePriorityExitButton extends StatelessWidget {
  const LivePriorityExitButton({
    required this.ar,
    required this.onExit,
    this.host = false,
    super.key,
  });

  final bool ar;
  final bool host;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: IconButton.filled(
      key: const ValueKey('live-priority-exit'),
      style: IconButton.styleFrom(
        backgroundColor: host
            ? const Color(0xFFAA2828)
            : const Color(0xDD173D31),
        foregroundColor: Colors.white,
        minimumSize: const Size(52, 52),
      ),
      tooltip: host
          ? (ar ? 'إنهاء البث المباشر' : 'End Live')
          : (ar ? 'مغادرة اللايف' : 'Leave Live'),
      onPressed: onExit,
      icon: Icon(host
          ? Icons.stop_circle_rounded
          : Icons.close_rounded),
    ),
  );
}
