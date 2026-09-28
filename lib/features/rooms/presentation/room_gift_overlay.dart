import 'package:flutter/material.dart';

import '../data/room_feature_models.dart';

class RoomGiftOverlay extends StatelessWidget {
  const RoomGiftOverlay({required this.event});

  final RoomGiftEvent event;

  String get _giftId => event.giftId.trim().toLowerCase();

  bool get _isPremiumDragon => const <String>{
        'dragon',
        'caraxes',
        'vhagar',
      }.contains(_giftId);

  String get _premiumTitle {
    switch (_giftId) {
      case 'vhagar':
        return 'VHAGAR';
      case 'caraxes':
      case 'dragon':
        return 'CARAXES';
      default:
        return event.giftId.toUpperCase();
    }
  }

  String get _fallbackEmoji => _giftId == 'vhagar' ? '🐲' : '🐉';

  Widget _catalogVisual({
    required double width,
    required double height,
    double fallbackSize = 110,
  }) {
    final url = event.animationUrl?.trim();
    if (url?.isNotEmpty == true) {
      return SizedBox(
        width: width,
        height: height,
        child: Image.network(
          url!,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => Center(
            child: Text(
              _fallbackEmoji,
              style: TextStyle(fontSize: fallbackSize),
            ),
          ),
        ),
      );
    }

    return Text(
      _fallbackEmoji,
      style: TextStyle(fontSize: fallbackSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isPremiumDragon) {
      return IgnorePointer(
        child: Material(
          color: Colors.black.withValues(alpha: .34),
          child: SafeArea(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: -1.15, end: 1.15),
              duration: const Duration(milliseconds: 4200),
              curve: Curves.easeInOutCubic,
              builder: (context, value, child) {
                final width = MediaQuery.sizeOf(context).width;
                final progress = ((value + 1.15) / 2.30).clamp(0.0, 1.0);
                final flightWave =
                    26 * (1 - (2 * progress - 1).abs()).clamp(0.0, 1.0);
                final fireOpacity = progress > .54 && progress < .90
                    ? ((progress - .54) / .20).clamp(0.0, 1.0) *
                        ((.90 - progress) / .16).clamp(0.0, 1.0)
                    : 0.0;

                return Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(
                                value.clamp(-1.0, 1.0),
                                -.15,
                              ),
                              radius: .75,
                              colors: [
                                const Color(0xFFFF5A1F).withValues(
                                  alpha: .12 + (.18 * fireOpacity),
                                ),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: (width * .5) + (value * width * .45) - 95,
                      top: 95 + flightWave,
                      child: Transform.rotate(
                        angle: value * .18,
                        child: _catalogVisual(
                          width: 190,
                          height: 190,
                          fallbackSize: 126,
                        ),
                      ),
                    ),
                    if (fireOpacity > 0)
                      Positioned(
                        right: 28,
                        top: 245,
                        child: Opacity(
                          opacity: fireOpacity,
                          child: const Text(
                            '🔥🔥🔥',
                            style: TextStyle(fontSize: 58),
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 108),
                        child: Opacity(
                          opacity: (1 - (progress - .76).clamp(0.0, .24) / .24)
                              .clamp(0.0, 1.0),
                          child: _GiftCaption(
                            event: event,
                            titleOverride: _premiumTitle,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    }

    final hasCatalogAnimation = event.animationUrl?.trim().isNotEmpty == true;
    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 78),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: .72, end: 1),
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) => Transform.scale(
                  scale: scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasCatalogAnimation)
                        _catalogVisual(
                          width: 150,
                          height: 150,
                          fallbackSize: 86,
                        ),
                      if (hasCatalogAnimation) const SizedBox(height: 8),
                      _GiftCaption(event: event),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GiftCaption extends StatelessWidget {
  const _GiftCaption({
    required this.event,
    this.titleOverride,
  });

  final RoomGiftEvent event;
  final String? titleOverride;

  @override
  Widget build(BuildContext context) {
    final icon = switch (event.giftId) {
      'dragon' => '🐉',
      'star' => '⭐',
      _ => '🌹',
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111D1A).withValues(alpha: .94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
        boxShadow: const [
          BoxShadow(blurRadius: 22, color: Colors.black45),
        ],
      ),
      child: Text(
        '$icon  ${event.senderName} → ${event.recipientName}  •  ${event.points}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

