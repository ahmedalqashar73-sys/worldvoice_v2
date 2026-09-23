import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/room_stage_models.dart';

class RoomStageGrid extends StatelessWidget {
  const RoomStageGrid({
    required this.seats,
    required this.showTeacherAiSeat,
    required this.onSeatTap,
    super.key,
  });

  final List<RoomSeatState> seats;
  final bool showTeacherAiSeat;
  final ValueChanged<RoomSeatState> onSeatTap;

  @override
  Widget build(BuildContext context) {
    final visibleSeats = <RoomSeatState>[
      ...seats.take(8),
      if (showTeacherAiSeat)
        const RoomSeatState(
          index: 9,
          role: RoomMemberRole.teacherAi,
          displayName: 'Teacher AI',
        ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleSeats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 10,
        childAspectRatio: .82,
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
      duration: const Duration(milliseconds: 1100),
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
    final isAi = seat.role == RoomMemberRole.teacherAi;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: widget.onTap,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  final glow = seat.isActiveSpeaker
                      ? 8 + (8 * math.sin(_pulse.value * math.pi))
                      : 0.0;

                  return Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _seatFrameGradient(seat, colors),
                      boxShadow: [
                        if (seat.isActiveSpeaker)
                          BoxShadow(
                            blurRadius: glow,
                            spreadRadius: 2,
                            color: colors.primary.withValues(alpha: .45),
                          ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.surfaceContainerHighest,
                      ),
                      child: ClipOval(
                        child: _SeatAvatar(seat: seat),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            seat.isEmpty ? 'Seat ${seat.index}' : seat.displayName ?? 'Speaker',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: seat.role == RoomMemberRole.host ||
                      seat.role == RoomMemberRole.coHost
                  ? FontWeight.w900
                  : FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoleBadge(role: seat.role),
              if (!seat.isEmpty && !isAi) ...[
                const SizedBox(width: 4),
                Icon(
                  seat.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  size: 13,
                  color: seat.isMuted ? colors.error : colors.primary,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  LinearGradient _seatFrameGradient(
    RoomSeatState seat,
    ColorScheme colors,
  ) {
    if (seat.role == RoomMemberRole.teacherAi) {
      return const LinearGradient(
        colors: [Color(0xFF6E5DFF), Color(0xFF16C79A)],
      );
    }
    if (seat.role == RoomMemberRole.vipSeat) {
      return const LinearGradient(
        colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
      );
    }
    if (seat.role == RoomMemberRole.host) {
      return const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFF5ABF63)],
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
      colors: [colors.outlineVariant, colors.outline],
    );
  }
}

class _SeatAvatar extends StatelessWidget {
  const _SeatAvatar({required this.seat});

  final RoomSeatState seat;

  @override
  Widget build(BuildContext context) {
    if (seat.role == RoomMemberRole.teacherAi) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.smart_toy_rounded, size: 36),
      );
    }

    if (seat.avatarUrl?.isNotEmpty == true) {
      return Image.network(
        seat.avatarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(
          Icons.person_rounded,
          size: 36,
        ),
      );
    }

    return Icon(
      seat.isEmpty ? Icons.add_rounded : Icons.person_rounded,
      size: seat.isEmpty ? 28 : 36,
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
      case RoomMemberRole.coHost:
        background = colors.secondaryContainer;
        foreground = colors.onSecondaryContainer;
      case RoomMemberRole.vipSeat:
        background = const Color(0xFFFFE0B2);
        foreground = const Color(0xFF7A4100);
      case RoomMemberRole.teacherAi:
        background = colors.primaryContainer;
        foreground = colors.onPrimaryContainer;
      case RoomMemberRole.speaker:
      case RoomMemberRole.listener:
        background = colors.surfaceContainerHighest;
        foreground = colors.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
