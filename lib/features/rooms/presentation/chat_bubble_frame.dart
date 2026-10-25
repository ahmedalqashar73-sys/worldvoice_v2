import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/chat_bubble_catalog.dart';

/// Responsive layered bubble art: content stretches; ornaments stay anchored.
/// The same design scales down in room chat and live comments.
class WorldVoiceBubbleFrame extends StatelessWidget {
  const WorldVoiceBubbleFrame({
    required this.design, required this.child, this.compact = false,
    this.showSignature = false, super.key,
  });
  final ChatBubbleDesign design;
  final Widget child;
  final bool compact, showSignature;

  @override
  Widget build(BuildContext context) {
    final tiny = compact;
    final royal = design.tier == ChatBubbleTier.royal;
    final vip = design.isVip;
    final radius = BorderRadius.only(
      topLeft: Radius.circular(tiny ? 14 : 22),
      topRight: Radius.circular(tiny ? 14 : 22),
      bottomLeft: Radius.circular(tiny ? 14 : 22),
      bottomRight: Radius.circular(tiny ? 7 : 13),
    );
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [design.primary, design.secondary, design.primary],
          stops: const [0, .68, 1],
        ),
        borderRadius: radius,
        border: Border.all(
          color: design.accent.withValues(alpha: royal || vip ? .98 : .76),
          width: royal || vip ? 1.9 : 1.35,
        ),
        boxShadow: [
          BoxShadow(color: design.primary.withValues(alpha: .27),
            blurRadius: royal ? 16 : 7, spreadRadius: 0.3),
          if (royal || vip) BoxShadow(
            color: design.accent.withValues(alpha: .14), blurRadius: 14),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: SvgPicture.asset(
                'assets/chat_bubbles/${design.id}.svg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          PositionedDirectional(
            top: tiny ? -3 : -5, start: tiny ? -4 : -7,
            child: Icon(design.icon,
              size: tiny ? 24 : 34,
              color: design.accent.withValues(alpha: .67)),
          ),
          PositionedDirectional(
            bottom: -4, end: -4,
            child: Icon(
              royal || vip ? Icons.auto_awesome_rounded : design.icon,
              size: tiny ? 18 : 27,
              color: design.accent.withValues(alpha: .63)),
          ),
          if (royal || vip)
            PositionedDirectional(
              top: tiny ? 3 : 5, end: tiny ? 13 : 19,
              child: Icon(Icons.star_rounded, size: tiny ? 9 : 13,
                color: design.accent.withValues(alpha: .9))),
          Padding(
            padding: EdgeInsets.fromLTRB(
              tiny ? 15 : 23, tiny ? 8 : 13,
              tiny ? 16 : 24, tiny ? 8 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showSignature) ...[
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(design.icon, size: 11, color: design.accent),
                    const SizedBox(width: 4),
                    Text('WorldVoice',
                      style: TextStyle(color: design.accent,
                        fontWeight: FontWeight.w800, fontSize: 10)),
                  ]),
                  const SizedBox(height: 4),
                ],
                DefaultTextStyle.merge(
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.38,
                    shadows: [Shadow(color: Color(0x66000000),
                      blurRadius: 3)],
                  ),
                  child: IconTheme.merge(data: const IconThemeData(
                    color: Colors.white), child: child),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
