import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

import '../data/classic_gift_mesh.dart';
import '../data/luxury_gift_catalog.dart';
import '../data/room_feature_models.dart';
import 'classic_gift_visual.dart';

/// Explicitly opt-in real mesh viewer. The 30-item scrolling gallery and
/// three-second voice-room gift FX keep using lightweight SVGs to avoid
/// creating WebViews in a live Agora audio session.
class ClassicGift3DStage extends StatefulWidget {
  const ClassicGift3DStage({
    required this.gift,
    this.height = 215,
    super.key,
  });

  final RoomGiftCatalogItem gift;
  final double height;

  @override
  State<ClassicGift3DStage> createState() => _ClassicGift3DStageState();
}

class _ClassicGift3DStageState extends State<ClassicGift3DStage> {
  late Future<String> _model;
  Flutter3DController? _luxuryController;
  bool _use3D = true;

  bool get _supported => kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    if (LuxuryGiftCatalog.assetFor(widget.gift.id) != null) {
      _luxuryController = Flutter3DController();
    }
    _model = Future<String>(() => ClassicGiftMesh.dataUri(widget.gift.id));
  }

  @override
  void didUpdateWidget(covariant ClassicGift3DStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gift.id != widget.gift.id) {
      _luxuryController = LuxuryGiftCatalog.assetFor(widget.gift.id) != null
          ? Flutter3DController() : null;
      _model = Future<String>(() => ClassicGiftMesh.dataUri(widget.gift.id));
      _use3D = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final luxuryAsset = LuxuryGiftCatalog.assetFor(widget.gift.id);
    final luxury = _supported && luxuryAsset != null;
    final interactive =
        luxury || (_supported && ClassicGiftMesh.supports(widget.gift.id));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: widget.height,
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const RadialGradient(
              colors: [Color(0xFF226E52), Color(0xFF0B3128)],
              radius: .94,
            ),
          ),
          child: luxury && _use3D
              ? Flutter3DViewer(
                  key: ValueKey('luxury3d:${widget.gift.id}'),
                  src: luxuryAsset,
                  controller: _luxuryController,
                  activeGestureInterceptor: true,
                  enableTouch: true,
                  progressBarColor: const Color(0xFFFFD98A),
                  onLoad: (_) {
                    _luxuryController?.startRotation(rotationSpeed: 8);
                  },
                  onError: (error) {
                    debugPrint('Luxury gift GLB failed: $error');
                    if (mounted) setState(() => _use3D = false);
                  },
                )
              : interactive && _use3D
              ? FutureBuilder<String>(
                  future: _model,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _fallback();
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFFFD98A)),
                      );
                    }
                    // ModelViewer bundles its JS; all model mesh data is
                    // generated locally, never fetched from a third party.
                    return ModelViewer(
                      key: ValueKey(widget.gift.id),
                      src: snapshot.data!,
                      alt: widget.gift.localizedName(ar),
                      ar: false,
                      autoRotate: true,
                      autoRotateDelay: 100,
                      cameraControls: true,
                      disablePan: true,
                      environmentImage: 'neutral',
                      backgroundColor: const Color(0xFF103D30),
                      debugLogging: false,
                    );
                  },
                )
              : _fallback(),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.view_in_ar_rounded,
              size: 17, color: Color(0xFFF2D492)),
          const SizedBox(width: 5),
          Text(interactive && _use3D
                  ? (ar ? 'مجسم 3D قابل للتدوير' : 'Interactive 3D mesh')
                  : (ar ? 'رسم الهدية' : 'Gift illustration'),
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFFE4EBD7))),
          const SizedBox(width: 12),
          if (interactive)
            TextButton(
              onPressed: () => setState(() => _use3D = !_use3D),
              child: Text(
                _use3D
                    ? (ar ? 'عرض الرسم' : 'View illustration')
                    : (ar ? 'عرض 3D' : 'View 3D'),
                style: const TextStyle(
                    color: Color(0xFFFFDA90), fontSize: 12),
              ),
            ),
        ]),
      ],
    );
  }

  Widget _fallback() => Center(
        child: ClassicGiftVisual(
          gift: widget.gift,
          size: widget.height * .79,
          animate: true,
        ),
      );
}
