import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import '../../rooms/presentation/voice_rooms_list.dart';

/// Live uses real Agora voice rooms with screen sharing rather than the old
/// fake streamer cards. Camera/video publishing requires a separate tested
/// implementation and is intentionally not advertised in this release.
class LiveScreen extends StatelessWidget {
  const LiveScreen({required this.localeController, super.key});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final language = localeController.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    final ar = language == 'ar';
    final rtl = const {'ar', 'ur', 'fa'}.contains(language);

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Card(
              color: const Color(0xFF124436),
              child: ListTile(
                leading: const Icon(Icons.live_tv_rounded,
                    color: Color(0xFFFFD57F)),
                title: Text(ar ? 'الغرف المباشرة' : 'Live rooms',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: Colors.white)),
                subtitle: Text(ar
                    ? 'صوت مباشر ومشاركة شاشة. بث الكاميرا قيد التطوير.'
                    : 'Live voice and screen sharing. Camera broadcasting is being developed.',
                    style: const TextStyle(color: Colors.white70)),
              ),
            ),
          ),
          Expanded(
            child: VoiceRoomsList(
              languageCode: language,
              localeController: localeController,
              onlyLive: true,
            ),
          ),
        ],
      ),
    );
  }
}
