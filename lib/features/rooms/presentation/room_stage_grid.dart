import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/room_stage_models.dart';

class RoomStageGrid extends StatelessWidget {
  const RoomStageGrid({
    required this.seats,
    required this.onSeatTap,
    super.key,
  });

  final List<RoomSeatState> seats;
  final ValueChanged<RoomSeatState> onSeatTap;

  @override
  Widget build(BuildContext context) {
    final stageSeats = seats.take(8).toList(growable: false);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stageSeats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        childAspectRatio: .76,
      ),
      itemBuilder: (context, index) {
        final seat = stageSeats[index];
        return _CompactRoomSeat(
          seat: seat,
          onTap: () => onSeatTap(seat),
        );
      },
    );
  }
}

class _CompactRoomSeat extends StatefulWidget {
  const _CompactRoomSeat({
    required this.seat,
    required this.onTap,
  });

  final RoomSeatState seat;
  final VoidCallback onTap;

  @override
  State<_CompactRoomSeat> createState() => _CompactRoomSeatState();
}

class _CompactRoomSeatState extends State<_CompactRoomSeat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
      lowerBound: 0,
      upperBound: 1,
    );
    if (widget.seat.isActiveSpeaker) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _CompactRoomSeat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seat.isActiveSpeaker && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.seat.isActiveSpeaker && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seat = widget.seat;
    final isAi = seat.role == RoomMemberRole.teacherAi;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: widget.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final glow = seat.isActiveSpeaker
                  ? 5 + (7 * math.sin(_pulse.value * math.pi))
                  : 0.0;

              return Container(
                width: 58,
                height: 58,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _frameGradient(seat),
                  boxShadow: [
                    if (seat.isActiveSpeaker)
                      BoxShadow(
                        blurRadius: glow,
                        spreadRadius: 2,
                        color: const Color(0xFF60FFB5).withValues(alpha: .75),
                      ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: seat.isEmpty
                        ? Colors.white.withValues(alpha: .16)
                        : const Color(0xFF19152F),
                  ),
                  child: ClipOval(child: _SeatAvatar(seat: seat)),
                ),
              );
            },
          ),
          const SizedBox(height: 5),
          Text(
            seat.isEmpty
                ? '${seat.index}'
                : (seat.displayName ?? seat.role.label),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: seat.isEmpty ? 11 : 12,
              fontWeight: seat.isEmpty ? FontWeight.w500 : FontWeight.w700,
            ),
          ),
          if (!seat.isEmpty) ...[
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isAi)
                  Icon(
                    seat.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    size: 11,
                    color: seat.isMuted
                        ? const Color(0xFFFF8C91)
                        : const Color(0xFF7FFFC3),
                  ),
                if (!isAi) const SizedBox(width: 3),
                _TinyRoleBadge(role: seat.role),
              ],
            ),
          ],
        ],
      ),
    );
  }

  LinearGradient _frameGradient(RoomSeatState seat) {
    if (seat.role == RoomMemberRole.teacherAi) {
      return const LinearGradient(
        colors: [Color(0xFF745CFF), Color(0xFF00E2A7)],
      );
    }
    if (seat.role == RoomMemberRole.host) {
      return const LinearGradient(
        colors: [Color(0xFFFFD900), Color(0xFF65E56C)],
      );
    }
    if (seat.role == RoomMemberRole.vipSeat) {
      return const LinearGradient(
        colors: [Color(0xFFFFD76A), Color(0xFFFF8A45)],
      );
    }
    if (seat.giftFrameLevel > 0) {
      return const LinearGradient(
        colors: [Color(0xFFBA67FF), Color(0xFFFF62B6)],
      );
    }
    if (seat.frameLevel > 0) {
      return const LinearGradient(
        colors: [Color(0xFF47CCFF), Color(0xFF6A79FF)],
      );
    }
    if (seat.isEmpty) {
      return LinearGradient(
        colors: [
          Colors.white.withValues(alpha: .25),
          Colors.white.withValues(alpha: .08),
        ],
      );
    }
    return const LinearGradient(
      colors: [Color(0xFF7E72A9), Color(0xFF514A75)],
    );
  }
}

class _SeatAvatar extends StatelessWidget {
  const _SeatAvatar({required this.seat});

  final RoomSeatState seat;

  @override
  Widget build(BuildContext context) {
    if (seat.role == RoomMemberRole.teacherAi) {
      return const ColoredBox(
        color: Color(0xFF282142),
        child: Icon(
          Icons.smart_toy_rounded,
          size: 27,
          color: Colors.white,
        ),
      );
    }

    if (seat.avatarUrl?.isNotEmpty == true) {
      return Image.network(
        seat.avatarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.person_rounded,
          size: 27,
          color: Colors.white,
        ),
      );
    }

    if (seat.isEmpty) {
      return Icon(
        Icons.pan_tool_alt_rounded,
        size: 23,
        color: Colors.white.withValues(alpha: .78),
      );
    }

    return const Icon(
      Icons.person_rounded,
      size: 27,
      color: Colors.white,
    );
  }
}

class _TinyRoleBadge extends StatelessWidget {
  const _TinyRoleBadge({required this.role});

  final RoomMemberRole role;

  @override
  Widget build(BuildContext context) {
    if (role == RoomMemberRole.speaker) {
      return const SizedBox.shrink();
    }

    final String label;
    final Color background;
    final Color foreground;

    switch (role) {
      case RoomMemberRole.host:
        label = 'Host';
        background = const Color(0xFFFFE082);
        foreground = const Color(0xFF5C4300);
        break;
      case RoomMemberRole.coHost:
        label = 'Co';
        background = const Color(0xFFB8B1FF);
        foreground = const Color(0xFF211B52);
        break;
      case RoomMemberRole.vipSeat:
        label = 'VIP';
        background = const Color(0xFFFFD28A);
        foreground = const Color(0xFF673E00);
        break;
      case RoomMemberRole.teacherAi:
        label = 'AI';
        background = const Color(0xFF62E7C0);
        foreground = const Color(0xFF073F31);
        break;
      case RoomMemberRole.listener:
        label = '';
        background = Colors.transparent;
        foreground = Colors.transparent;
        break;
      case RoomMemberRole.speaker:
        label = '';
        background = Colors.transparent;
        foreground = Colors.transparent;
        break;
    }

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
