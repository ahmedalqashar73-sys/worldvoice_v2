import 'dart:async';

import 'package:flutter/material.dart';

import '../services/agora_voice_room_controller.dart';

class AgoraVoiceRoomScreen extends StatefulWidget {
  const AgoraVoiceRoomScreen({
    required this.channelId,
    required this.roomName,
    required this.initialRole,
    super.key,
  });

  final String channelId;
  final String roomName;
  final AgoraRoomRole initialRole;

  @override
  State<AgoraVoiceRoomScreen> createState() => _AgoraVoiceRoomScreenState();
}

class _AgoraVoiceRoomScreenState extends State<AgoraVoiceRoomScreen> {
  late final AgoraVoiceRoomController _controller;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _controller = AgoraVoiceRoomController()..addListener(_refresh);
    unawaited(
      _controller.connect(
        channelId: widget.channelId,
        role: widget.initialRole,
      ),
    );
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;

    try {
      await _controller.leave();
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    unawaited(_controller.leave());
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isSpeaker = _controller.role == AgoraRoomRole.speaker;

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _leave,
            icon: const Icon(Icons.close_rounded),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.roomName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.channelId,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                child: _ConnectionBanner(controller: _controller),
              ),
              if (_controller.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Card(
                    color: colors.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: colors.onErrorContainer,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _controller.error!,
                              style: TextStyle(
                                color: colors.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  children: [
                    Text(
                      'Stage',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 14,
                      runSpacing: 16,
                      children: [
                        if (isSpeaker)
                          _SpeakerSeat(
                            label: 'You',
                            sublabel: _controller.muted ? 'Muted' : 'Speaking',
                            muted: _controller.muted,
                            local: true,
                          ),
                        for (final uid in _controller.remoteSpeakers)
                          _SpeakerSeat(
                            label: 'Speaker',
                            sublabel: 'UID $uid',
                            muted: false,
                          ),
                        if (!isSpeaker &&
                            _controller.remoteSpeakers.isEmpty)
                          const _EmptyStage(),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Card(
                      child: ListTile(
                        leading: Icon(
                          isSpeaker
                              ? Icons.mic_rounded
                              : Icons.headphones_rounded,
                        ),
                        title: Text(
                          isSpeaker ? 'Speaker' : 'Listener',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        subtitle: Text(
                          isSpeaker
                              ? 'Your microphone can publish audio to the room.'
                              : 'You receive room audio without publishing your microphone.',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(
                    top: BorderSide(color: colors.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    if (isSpeaker)
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _controller.joined
                              ? () => _controller.setMuted(
                                    !_controller.muted,
                                  )
                              : null,
                          icon: Icon(
                            _controller.muted
                                ? Icons.mic_off_rounded
                                : Icons.mic_rounded,
                          ),
                          label: Text(
                            _controller.muted ? 'Unmute' : 'Mute',
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _controller.joined
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Raise Hand moderation is the next room step.',
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.pan_tool_alt_rounded),
                          label: const Text('Raise hand'),
                        ),
                      ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _leave,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.error,
                        foregroundColor: colors.onError,
                      ),
                      child: const Icon(Icons.call_end_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.controller});

  final AgoraVoiceRoomController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final String text;
    final IconData icon;
    if (controller.joined) {
      text = 'Connected to Agora';
      icon = Icons.cloud_done_rounded;
    } else if (controller.connecting) {
      text = 'Connecting to Agora…';
      icon = Icons.sync_rounded;
    } else {
      text = 'Not connected';
      icon = Icons.cloud_off_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: controller.joined
            ? colors.primaryContainer.withValues(alpha: .55)
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (controller.connecting)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _SpeakerSeat extends StatelessWidget {
  const _SpeakerSeat({
    required this.label,
    required this.sublabel,
    required this.muted,
    this.local = false,
  });

  final String label;
  final String sublabel;
  final bool muted;
  final bool local;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 92,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: local
                    ? colors.primaryContainer
                    : colors.secondaryContainer,
                child: Icon(
                  local ? Icons.person_rounded : Icons.record_voice_over_rounded,
                  size: 34,
                ),
              ),
              PositionedDirectional(
                end: -2,
                bottom: -2,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor:
                      muted ? colors.error : colors.primary,
                  child: Icon(
                    muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    color: muted ? colors.onError : colors.onPrimary,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            sublabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _EmptyStage extends StatelessWidget {
  const _EmptyStage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(Icons.mic_none_rounded, size: 38),
          SizedBox(height: 8),
          Text('Waiting for speakers…'),
        ],
      ),
    );
  }
}
