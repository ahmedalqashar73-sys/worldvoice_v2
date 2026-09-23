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
    final visibleSeats = seats.take(8).toList(growable: false);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleSeats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 8,
        childAspectRatio: .70,
      ),
      itemBuilder: (context, index) {
        final seat = visibleSeats[index];
        return _RoomSeat(
          seat: seat,
          onTap: () => onSeatTap(seat),
        );
      },
    );
  }
}

class _RoomSeat extends StatefulWidget {
  const _RoomSeat({
    required this.seat,
    required this.onTap,
  });

  final RoomSeatState seat;
  final VoidCallback onTap;

  @override
  State<_RoomSeat> createState() => _RoomSeatState();
}

class _RoomSeatState extends State<_RoomSeat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
      lowerBound: 0,
      upperBound: 1,
    );
    if (widget.seat.isActiveSpeaker) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _RoomSeat oldWidget) {
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
    final colors = Theme.of(context).colorScheme;

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
                  ? 7 + (7 * math.sin(_pulse.value * math.pi))
                  : 0.0;

              return Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _seatFrameGradient(seat, colors),
                  boxShadow: [
                    if (seat.isActiveSpeaker)
                      BoxShadow(
                        blurRadius: glow,
                        spreadRadius: 2,
                        color: colors.primary.withValues(alpha: .50),
                      ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: seat.isEmpty
                        ? colors.surfaceContainerHighest
                        : colors.surface,
                  ),
                  child: ClipOval(
                    child: _SeatAvatar(seat: seat),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 7),
          Text(
            seat.isEmpty ? '${seat.index}' : seat.displayName ?? 'Speaker',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: seat.role == RoomMemberRole.host ||
                      seat.role == RoomMemberRole.coHost
                  ? FontWeight.w900
                  : FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          if (!seat.isEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoleBadge(role: seat.role),
                const SizedBox(width: 3),
                Icon(
                  seat.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  size: 12,
                  color: seat.isMuted ? colors.error : colors.primary,
                ),
              ],
            )
          else
            Icon(
              Icons.pan_tool_alt_rounded,
              size: 12,
              color: colors.onSurfaceVariant.withValues(alpha: .70),
            ),
        ],
      ),
    );
  }

  LinearGradient _seatFrameGradient(
    RoomSeatState seat,
    ColorScheme colors,
  ) {
    if (seat.role == RoomMemberRole.vipSeat) {
      return const LinearGradient(
        colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
      );
    }
    if (seat.role == RoomMemberRole.host) {
      return const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFF62D64F)],
      );
    }
    if (seat.role == RoomMemberRole.coHost) {
      return const LinearGradient(
        colors: [Color(0xFF7C5CFF), Color(0xFF27C7B8)],
      );
    }
    if (seat.giftFrameLevel > 0) {
      return const LinearGradient(
        colors: [Color(0xFFAA63FF), Color(0xFFFF5CA8)],
      );
    }
    if (seat.frameLevel > 0) {
      return const LinearGradient(
        colors: [Color(0xFF37B9FF), Color(0xFF5E73FF)],
      );
    }
    return LinearGradient(
      colors: [
        colors.outlineVariant,
        colors.outline.withValues(alpha: .75),
      ],
    );
  }
}

class _SeatAvatar extends StatelessWidget {
  const _SeatAvatar({required this.seat});

  final RoomSeatState seat;

  @override
  Widget build(BuildContext context) {
    if (seat.avatarUrl?.isNotEmpty == true) {
      return Image.network(
        seat.avatarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.person_rounded,
          size: 30,
        ),
      );
    }

    return Icon(
      seat.isEmpty ? Icons.chair_alt_rounded : Icons.person_rounded,
      size: seat.isEmpty ? 27 : 31,
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final RoomMemberRole role;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Color background;
    Color foreground;
    switch (role) {
      case RoomMemberRole.host:
        background = const Color(0xFFFFE082);
        foreground = const Color(0xFF5C4300);
        break;
      case RoomMemberRole.coHost:
        background = colors.secondaryContainer;
        foreground = colors.onSecondaryContainer;
        break;
      case RoomMemberRole.vipSeat:
        background = const Color(0xFFFFE0B2);
        foreground = const Color(0xFF7A4100);
        break;
      case RoomMemberRole.speaker:
        background = colors.surfaceContainerHighest;
        foreground = colors.onSurfaceVariant;
        break;
      case RoomMemberRole.listener:
      case RoomMemberRole.teacherAi:
        background = colors.surfaceContainerHighest;
        foreground = colors.onSurfaceVariant;
        break;
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 54),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
