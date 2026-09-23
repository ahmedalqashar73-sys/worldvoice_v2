import 'dart:async';

import 'package:flutter/material.dart';

import '../data/room_stage_models.dart';
import '../services/agora_voice_room_controller.dart';
import 'room_stage_grid.dart';

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
  bool _showTeacherAiSeat = true;
  bool _handRaised = false;

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

  List<RoomSeatState> _buildSeats() {
    final seats = List<RoomSeatState>.generate(
      8,
      (index) => RoomSeatState(
        index: index + 1,
        role: RoomMemberRole.speaker,
      ),
    );

    var cursor = 0;
    if (_controller.role == AgoraRoomRole.speaker) {
      seats[0] = RoomSeatState(
        index: 1,
        role: RoomMemberRole.host,
        displayName: 'You',
        agoraUid: _controller.localUid,
        isMuted: _controller.muted,
        isLocalUser: true,
      );
      cursor = 1;
    }

    for (final uid in _controller.remoteSpeakers) {
      if (cursor >= 8) break;
      seats[cursor] = RoomSeatState(
        index: cursor + 1,
        role: RoomMemberRole.speaker,
        displayName: 'Speaker',
        agoraUid: uid,
      );
      cursor++;
    }

    return seats;
  }

  bool get _isHost => _controller.role == AgoraRoomRole.speaker;

  void _handleSeatTap(RoomSeatState seat) {
    if (!_isHost) return;

    if (seat.isEmpty) {
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: ListTile(
            leading: const Icon(Icons.person_add_alt_1_rounded),
            title: const Text('Invite listener to this seat'),
            subtitle: const Text(
              'Listener selection and host invitation sync will be connected in the moderation step.',
            ),
            onTap: () => Navigator.pop(sheetContext),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.manage_accounts_rounded),
          title: Text(seat.displayName ?? seat.role.label),
          subtitle: Text(seat.role.label),
          onTap: () => Navigator.pop(sheetContext),
        ),
      ),
    );
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
                    RoomStageGrid(
                      seats: _buildSeats(),
                      showTeacherAiSeat: _showTeacherAiSeat,
                      onSeatTap: _handleSeatTap,
                    ),
                    const SizedBox(height: 20),
                    if (_isHost)
                      Card(
                        child: SwitchListTile(
                          secondary: const Icon(Icons.smart_toy_rounded),
                          title: const Text(
                            'Teacher AI seat',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: const Text(
                            'Show or hide seat 9. AI connection comes later.',
                          ),
                          value: _showTeacherAiSeat,
                          onChanged: (value) {
                            setState(() => _showTeacherAiSeat = value);
                          },
                        ),
                      ),
                    Card(
                      child: ListTile(
                        leading: Icon(
                          isSpeaker
                              ? Icons.admin_panel_settings_rounded
                              : Icons.headphones_rounded,
                        ),
                        title: Text(
                          isSpeaker ? 'Host' : 'Listener',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        subtitle: Text(
                          isSpeaker
                              ? 'Host controls are enabled for this test room.'
                              : _handRaised
                                  ? 'Hand raised — waiting for host approval.'
                                  : 'You are listening to the room.',
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
                                  setState(() => _handRaised = !_handRaised);
                                }
                              : null,
                          icon: Icon(
                            _handRaised
                                ? Icons.pan_tool_rounded
                                : Icons.pan_tool_alt_rounded,
                          ),
                          label: Text(
                            _handRaised ? 'Cancel hand' : 'Raise hand',
                          ),
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

