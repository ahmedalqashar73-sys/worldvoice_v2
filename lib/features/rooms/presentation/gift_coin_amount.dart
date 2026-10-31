import 'package:flutter/material.dart';

/// A resolution-independent WorldVoice coin shared by gift prices and effects.
class GiftCoinAmount extends StatelessWidget {
  const GiftCoinAmount({required this.amount, this.style, super.key});

  final int amount;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final size = (style?.fontSize ?? 14) * 1.25;
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF0AE),
                    Color(0xFFFFD15C),
                    Color(0xFFBC7F1E),
                  ],
                ),
                border: Border.all(color: const Color(0xFFFFE6A0)),
              ),
              child: Text(
                'W',
                textDirection: TextDirection.ltr,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: const Color(0xFF735014),
                  fontSize: size * .62,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          TextSpan(text: ' $amount'),
        ],
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      semanticsLabel: ar
          ? '$amount كوينز WorldVoice'
          : '$amount WorldVoice coins',
      style: style,
    );
  }
}
