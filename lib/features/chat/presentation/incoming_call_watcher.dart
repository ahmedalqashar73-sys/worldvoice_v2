import 'dart:async';

import 'package:flutter/material.dart';

import '../services/chat_call_service.dart';
import 'chat_call_screen.dart';

class IncomingCallWatcher extends StatefulWidget {
  const IncomingCallWatcher({required this.child, super.key});
  final Widget child;

  @override
  State<IncomingCallWatcher> createState() => _IncomingCallWatcherState();
}

class _IncomingCallWatcherState extends State<IncomingCallWatcher>
    with WidgetsBindingObserver {
  final ChatCallService _service = ChatCallService();
  Timer? _timer;
  String? _showingCallId;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => unawaited(_check()),
    );
    unawaited(_check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _start();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _timer?.cancel();
    }
  }

  Future<void> _check() async {
    if (_checking || _showingCallId != null || !mounted) return;
    _checking = true;
    try {
      final call = await _service.incoming();
      if (!mounted || call == null || call.id.isEmpty) return;
      _showingCallId = call.id;
      await _showIncoming(call);
    } catch (_) {
      // Polling is best effort while the chat tab is open.
    } finally {
      _checking = false;
    }
  }

  Future<void> _showIncoming(ChatCallInfo call) async {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final photo = call.callerPhotoUrl.trim();
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          call.isVideo
              ? (ar ? 'مكالمة فيديو واردة' : 'Incoming video call')
              : (ar ? 'مكالمة صوتية واردة' : 'Incoming voice call'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 38,
              backgroundImage: photo.isEmpty ? null : NetworkImage(photo),
              child: photo.isEmpty
                  ? const Icon(Icons.person_rounded, size: 38)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              call.callerName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(dialogContext, 'decline'),
            icon: const Icon(Icons.call_end_rounded, color: Colors.redAccent),
            label: Text(ar ? 'رفض' : 'Decline'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, 'accept'),
            icon: const Icon(Icons.call_rounded),
            label: Text(ar ? 'قبول' : 'Accept'),
          ),
        ],
      ),
    );

    try {
      if (action == 'accept') {
        await _service.respond(callId: call.id, action: 'accept');
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ChatCallScreen(
              call: call,
              peerName: call.callerName,
              peerPhotoUrl: call.callerPhotoUrl,
              accepted: true,
            ),
          ),
        );
      } else {
        await _service.respond(callId: call.id, action: 'decline');
      }
    } finally {
      _showingCallId = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}