import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Keeps the room at its full height while docking chat above the keyboard.
/// The conversation can cover the bottom of the room on a small screen, but
/// never removes or recreates the board, seats, or Teacher AI.
class RoomKeyboardLayout extends StatelessWidget {
  const RoomKeyboardLayout({
    required this.room,
    required this.conversation,
    required this.keyboardInset,
    super.key,
  });

  final Widget room;
  final Widget conversation;
  final double keyboardInset;

  @override
  Widget build(BuildContext context) => CustomMultiChildLayout(
    delegate: _RoomKeyboardDelegate(keyboardInset),
    children: [
      LayoutId(id: _RoomPart.room, child: room),
      LayoutId(
        id: _RoomPart.conversation,
        child: ColoredBox(
          color: keyboardInset > 0
              ? const Color(0xFF0D3028)
              : Colors.transparent,
          child: conversation,
        ),
      ),
    ],
  );
}

enum _RoomPart { room, conversation }

class _RoomKeyboardDelegate extends MultiChildLayoutDelegate {
  _RoomKeyboardDelegate(this.keyboardInset);

  final double keyboardInset;

  @override
  void performLayout(Size size) {
    final roomSize = layoutChild(
      _RoomPart.room,
      BoxConstraints(
        maxWidth: size.width,
        maxHeight: size.height,
        minWidth: size.width,
      ),
    );
    positionChild(_RoomPart.room, Offset.zero);

    final available = math.max(0.0, size.height - keyboardInset);
    final minimumChat = math.min(keyboardInset > 0 ? 130.0 : 200.0, available);
    final chatHeight = (available - roomSize.height).clamp(
      minimumChat,
      available,
    );
    layoutChild(
      _RoomPart.conversation,
      BoxConstraints.tight(Size(size.width, chatHeight)),
    );
    positionChild(_RoomPart.conversation, Offset(0, available - chatHeight));
  }

  @override
  bool shouldRelayout(_RoomKeyboardDelegate oldDelegate) =>
      keyboardInset != oldDelegate.keyboardInset;
}
