import 'package:flutter/material.dart';

/// Live stage placeholder used by both the host and viewers when a camera
/// is deliberately disabled. A missing/broken profile photo never exposes a
/// black or blank camera tile, and the content fits a four-person grid.
class LiveCameraOffTile extends StatelessWidget {
  const LiveCameraOffTile({
    required this.ar,
    this.photoUrl = '',
    super.key,
  });

  final bool ar;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(photoUrl.trim());
    final validPhoto = uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
    return DecoratedBox(
      key: const ValueKey('live-camera-off-state'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF197654),
            Color(0xFF10523D),
            Color(0xFF0A3D31),
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxHeight < 150 || constraints.maxWidth < 140;
          final radius =
              (constraints.biggest.shortestSide * .15).clamp(16.0, 52.0);
          final fallback = Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: radius,
          );
          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFF2D596), Color(0xFF0EB78A)],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: radius,
                      backgroundColor: const Color(0xFF164434),
                      child: validPhoto
                          ? ClipOval(
                              child: Image.network(
                                uri.toString(),
                                width: radius * 2,
                                height: radius * 2,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => fallback,
                              ),
                            )
                          : fallback,
                    ),
                  ),
                  SizedBox(height: compact ? 5 : 12),
                  Icon(
                    Icons.videocam_off_rounded,
                    size: compact ? 17 : 22,
                    color: const Color(0xFFD4E9E2),
                  ),
                  SizedBox(height: compact ? 2 : 5),
                  Text(
                    ar ? 'الكاميرا مغلقة' : 'Camera off',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFE5F2EC),
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 10 : 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
