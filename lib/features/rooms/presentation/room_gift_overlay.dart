import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/room_feature_models.dart';

class RoomGiftOverlay extends StatefulWidget {
  const RoomGiftOverlay({
    required this.event,
    required this.onFinished,
    super.key,
  });

  final RoomGiftEvent event;
  final VoidCallback onFinished;

  @override
  State<RoomGiftOverlay> createState() => _RoomGiftOverlayState();
}

class _RoomGiftOverlayState extends State<RoomGiftOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _isDragon => widget.event.giftId == 'dragon';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _isDragon ? 4300 : 2200),
    )..forward().whenComplete(widget.onFinished);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDragon) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final x = -1.4 + (2.8 * Curves.easeInOut.transform(t.clamp(0, .72) / .72));
          final y = -.55 + (.50 * math.sin(t * math.pi * 2));
          final scale = t < .15
              ? .35 + (t / .15) * .65
              : t > .84
                  ? 1 - ((t - .84) / .16) * .30
                  : 1.0;
          final fireOpacity = t > .55 && t < .90
              ? math.sin(((t - .55) / .35) * math.pi).clamp(0, 1).toDouble()
              : 0.0;

          return IgnorePointer(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(
                      alpha: .18 * math.sin(t * math.pi),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment(x, y),
                  child: Transform.rotate(
                    angle: math.sin(t * math.pi * 4) * .16,
                    child: Transform.scale(
                      scale: scale,
                      child: const Text(
                        '🐉',
                        style: TextStyle(fontSize: 118),
                      ),
                    ),
                  ),
                ),
                if (fireOpacity > 0)
                  Align(
                    alignment: const Alignment(.50, .15),
                    child: Opacity(
                      opacity: fireOpacity,
                      child: const Text(
                        '🔥🔥🔥',
                        style: TextStyle(fontSize: 62),
                      ),
                    ),
                  ),
                Align(
                  alignment: const Alignment(0, .72),
                  child: Opacity(
                    opacity: math.sin(t * math.pi).clamp(0, 1).toDouble(),
                    child: _GiftCaption(
                      title: 'CARAXES',
                      sender: widget.event.senderName,
                      recipient: widget.event.recipientName,
                      points: widget.event.points,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    final emoji = widget.event.giftId == 'star' ? '⭐' : '🌹';
    return IgnorePointer(
      child: Center(
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: _controller,
            curve: const Interval(0, .35, curve: Curves.elasticOut),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: const Interval(.65, 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 88)),
                const SizedBox(height: 10),
                _GiftCaption(
                  title: widget.event.giftId.toUpperCase(),
                  sender: widget.event.senderName,
                  recipient: widget.event.recipientName,
                  points: widget.event.points,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GiftCaption extends StatelessWidget {
  const _GiftCaption({
    required this.title,
    required this.sender,
    required this.recipient,
    required this.points,
  });

  final String title;
  final String sender;
  final String recipient;
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$sender → $recipient • $points pts',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
