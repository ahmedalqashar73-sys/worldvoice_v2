import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import '../../rooms/presentation/voice_rooms_list.dart';
import '../../rooms/presentation/unified_gift_panel.dart';

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  showDragHandle: true,
                  builder: (sheet) => SizedBox(
                    height: MediaQuery.sizeOf(sheet).height * .76,
                    child: const UnifiedGiftPanel(
                      contextType: 'live',
                      contextId: 'preview',
                      recipients: <String, String>{},
                    ),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFF11835D)),
                label: Text(ar ? 'تجربة الهدايا الثلاثين'
                    : 'Preview the 30 gifts',
                  style: const TextStyle(color: Color(0xFF11835D),
                      fontWeight: FontWeight.bold)),
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
