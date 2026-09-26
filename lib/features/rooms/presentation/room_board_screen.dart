import 'dart:async';
import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/room_feature_models.dart';
import '../services/agora_voice_room_controller.dart';
import '../services/room_board_service.dart';
import '../services/room_device_media_store.dart';
import 'room_device_media_viewer.dart';
import '../services/room_feature_service.dart';

class RoomBoardScreen extends StatefulWidget {
  const RoomBoardScreen({
    required this.roomId,
    required this.canWrite,
    required this.isHost,
    required this.agoraController,
    super.key,
  });

  final String roomId;
  final bool canWrite;
  final bool isHost;
  final AgoraVoiceRoomController agoraController;

  @override
  State<RoomBoardScreen> createState() => _RoomBoardScreenState();
}

class _RoomBoardScreenState extends State<RoomBoardScreen> {
  late final RoomBoardService _service;
  late final RoomFeatureService _features;
  final List<Offset> _draft = <Offset>[];
  final RoomDeviceMediaStore _deviceMedia = RoomDeviceMediaStore();
  List<RoomDeviceMedia> _localFiles = const <RoomDeviceMedia>[];
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _service = RoomBoardService(roomId: widget.roomId);
    _features = RoomFeatureService(roomId: widget.roomId);
    unawaited(_loadLocalFiles());
  }

  Future<void> _startScreenShare() async {
    await widget.agoraController.startScreenShare();
    final uid = widget.agoraController.localUid;
    if (uid != null) {
      await _features.setScreenSharing(
        active: true,
        sharerUid: uid,
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _stopScreenShare() async {
    await widget.agoraController.stopScreenShare();
    await _features.setScreenSharing(active: false);
    if (mounted) setState(() {});
  }

  Future<void> _addText() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Board text'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          maxLength: 300,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value?.isNotEmpty == true) {
      await _service.addText(value!);
    }
  }

  Future<void> _loadLocalFiles() async {
    try {
      final files = await _deviceMedia.load();
      if (mounted) setState(() => _localFiles = files);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Local media library: ' + error.toString())),
      );
    }
  }

  Future<void> _importToDevice(String type) async {
    final FileType pickerType;
    final List<String>? extensions;
    switch (type) {
      case 'image':
        pickerType = FileType.image;
        extensions = null;
        break;
      case 'video':
        pickerType = FileType.video;
        extensions = null;
        break;
      case 'pdf':
        pickerType = FileType.custom;
        extensions = const ['pdf'];
        break;
      default:
        return;
    }

    final picked = await FilePicker.pickFile(
      type: pickerType,
      allowedExtensions: extensions,
    );
    if (picked == null) return;
    if (picked.path == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not access the chosen device file.')),
        );
      }
      return;
    }

    setState(() => _uploading = true);
    try {
      final imported = await _deviceMedia.importFile(
        sourcePath: picked.path!,
        name: picked.name,
        type: type,
      );
      await _loadLocalFiles();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            imported.name +
                ' is saved on this phone only. Start screen sharing '
                'to show it to room members.',
          ),
        ),
      );
      // Nothing gets uploaded to Cloudinary or saved as room media metadata.
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save this file: ' + error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removeLocalFile(RoomDeviceMedia media) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove local file?'),
        content: Text(
          'Remove "' + media.name + '" from WorldVoice storage on this phone? '
          'The original file in Downloads or Gallery will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove copy'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _deviceMedia.remove(media);
    await _loadLocalFiles();
  }

  Future<void> _saveStroke(Size size) async {
    if (_draft.length < 2 || size.width <= 0 || size.height <= 0) {
      _draft.clear();
      return;
    }

    final normalized = _draft
        .map(
          (point) => <String, double>{
            'x': (point.dx / size.width).clamp(0, 1),
            'y': (point.dy / size.height).clamp(0, 1),
          },
        )
        .toList(growable: false);

    _draft.clear();
    await _service.addStroke(
      points: normalized,
      colorValue: Colors.white.toARGB32(),
      width: 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'السبورة المشتركة' : 'Shared board'),
        actions: [
          if (widget.isHost)
            IconButton(
              tooltip: isArabic ? 'مسح السبورة' : 'Clear board',
              onPressed: _service.clear,
              icon: const Icon(Icons.delete_sweep_rounded),
            ),
        ],
      ),
      body: StreamBuilder<RoomFeatureState>(
        stream: _features.watchState(),
        builder: (context, featureSnapshot) {
          final featureState = featureSnapshot.data;
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _service.watchItems(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ??
                  const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          final strokes = docs
              .where((doc) => doc.data()['type'] == 'stroke')
              .toList(growable: false);
          final content = docs
              .where((doc) => doc.data()['type'] != 'stroke')
              .toList(growable: false);

          return Column(
            children: [
              if (featureState?.screenShareActive == true)
                _LiveScreenShare(
                  roomId: widget.roomId,
                  sharerUid: featureState?.screenSharerUid,
                  controller: widget.agoraController,
                ),
              if (widget.isHost)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton.tonalIcon(
                      onPressed: widget.agoraController.screenSharing
                          ? _stopScreenShare
                          : _startScreenShare,
                      icon: Icon(
                        widget.agoraController.screenSharing
                            ? Icons.stop_screen_share_rounded
                            : Icons.screen_share_rounded,
                      ),
                      label: Text(
                        widget.agoraController.screenSharing
                            ? (isArabic ? 'إيقاف مشاركة الشاشة' : 'Stop screen share')
                            : (isArabic ? 'مشاركة شاشة الجوال' : 'Share phone screen'),
                      ),
                    ),
                  ),
                ),
              Expanded(
                flex: featureState?.screenShareActive == true ? 3 : 5,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: widget.canWrite
                          ? (details) {
                              _draft
                                ..clear()
                                ..add(details.localPosition);
                              setState(() {});
                            }
                          : null,
                      onPanUpdate: widget.canWrite
                          ? (details) {
                              _draft.add(details.localPosition);
                              setState(() {});
                            }
                          : null,
                      onPanEnd: widget.canWrite
                          ? (_) => _saveStroke(size)
                          : null,
                      child: CustomPaint(
                        painter: _BoardPainter(
                          strokes: strokes,
                          draft: _draft,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF161626),
                            border: Border.all(color: Colors.white12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (content.isNotEmpty)
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(10),
                    scrollDirection: Axis.horizontal,
                    itemCount: content.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) =>
                        _BoardContentCard(data: content[index].data()),
                  ),
                ),
              if (_localFiles.isNotEmpty)
                SizedBox(
                  height: 166,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(12, 5, 12, 5),
                        child: Text(
                          isArabic
                              ? 'ملفاتي على هذا الجوال (خاصة، ليست على الخادم)'
                              : 'My phone files (private, not on the server)',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: _localFiles.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final media = _localFiles[index];
                            final icon = switch (media.type) {
                              'pdf' => Icons.picture_as_pdf_rounded,
                              'video' => Icons.play_circle_fill_rounded,
                              _ => Icons.image_rounded,
                            };
                            return SizedBox(
                              width: 140,
                              child: Card(
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () =>
                                      RoomDeviceMediaViewer.open(context, media),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: media.type == 'image'
                                            ? Image.file(
                                                File(media.path),
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                errorBuilder: (_, _, _) =>
                                                    Icon(icon, size: 38),
                                              )
                                            : Center(child: Icon(icon, size: 38)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsetsDirectional.only(
                                          start: 8,
                                          end: 2,
                                          bottom: 2,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                media.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ),
                                            IconButton(
                                              iconSize: 18,
                                              constraints: const BoxConstraints(),
                                              tooltip: isArabic
                                                  ? 'حذف النسخة المحلية'
                                                  : 'Remove local copy',
                                              onPressed: () =>
                                                  _removeLocalFile(media),
                                              icon: const Icon(
                                                Icons.delete_outline_rounded,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.canWrite)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _addText,
                          icon: const Icon(Icons.text_fields_rounded),
                          label: Text(isArabic ? 'نص' : 'Text'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed:
                              _uploading ? null : () => _importToDevice('image'),
                          icon: const Icon(Icons.image_rounded),
                          label: Text(isArabic ? 'صورة من الجوال' : 'Phone image'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed:
                              _uploading ? null : () => _importToDevice('video'),
                          icon: const Icon(Icons.video_file_rounded),
                          label: Text(isArabic ? 'فيديو من الجوال' : 'Phone video'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed:
                              _uploading ? null : () => _importToDevice('pdf'),
                          icon: const Icon(Icons.picture_as_pdf_rounded),
                          label: Text(isArabic ? 'PDF من الجوال' : 'Phone PDF'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
            },
          );
        },
      ),
    );
  }
}

class _LiveScreenShare extends StatelessWidget {
  const _LiveScreenShare({
    required this.roomId,
    required this.sharerUid,
    required this.controller,
  });

  final String roomId;
  final int? sharerUid;
  final AgoraVoiceRoomController controller;

  @override
  Widget build(BuildContext context) {
    final uid = sharerUid;
    if (uid == null || controller.engine == null) {
      return const SizedBox.shrink();
    }
    return Container(
      height: 232,
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: _AgoraScreenView(
              roomId: roomId,
              sharerUid: uid,
              controller: controller,
            ),
          ),
          PositionedDirectional(
            top: 6,
            end: 6,
            child: IconButton.filledTonal(
              tooltip: 'Full screen',
              icon: const Icon(Icons.fullscreen_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    backgroundColor: Colors.black,
                    appBar: AppBar(
                      title: const Text('Live screen'),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    body: SafeArea(
                      child: _AgoraScreenView(
                        roomId: roomId,
                        sharerUid: uid,
                        controller: controller,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Uses the Agora screen-capture video source for the local owner instead of
/// a permanent "Your screen is live" placeholder.
class _AgoraScreenView extends StatelessWidget {
  const _AgoraScreenView({
    required this.roomId,
    required this.sharerUid,
    required this.controller,
  });

  final String roomId;
  final int sharerUid;
  final AgoraVoiceRoomController controller;

  @override
  Widget build(BuildContext context) {
    final engine = controller.engine;
    if (engine == null) {
      return const Center(
        child: Text('Waiting for the screen stream...',
            style: TextStyle(color: Colors.white)),
      );
    }
    final isLocal = sharerUid == controller.localUid;
    return AgoraVideoView(
      controller: isLocal
          ? VideoViewController(
              rtcEngine: engine,
              canvas: const VideoCanvas(
                uid: 0,
                sourceType: VideoSourceType.videoSourceScreen,
                renderMode: RenderModeType.renderModeFit,
              ),
            )
          : VideoViewController.remote(
              rtcEngine: engine,
              canvas: VideoCanvas(
                uid: sharerUid,
                sourceType: VideoSourceType.videoSourceRemote,
                renderMode: RenderModeType.renderModeFit,
              ),
              connection: RtcConnection(channelId: roomId),
            ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.strokes,
    required this.draft,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> strokes;
  final List<Offset> draft;

  @override
  void paint(Canvas canvas, Size size) {
    for (final doc in strokes) {
      final data = doc.data();
      final rawPoints = data['points'] as List? ?? const [];
      final points = rawPoints
          .whereType<Map>()
          .map(
            (raw) => Offset(
              ((raw['x'] as num?)?.toDouble() ?? 0) * size.width,
              ((raw['y'] as num?)?.toDouble() ?? 0) * size.height,
            ),
          )
          .toList(growable: false);
      _drawLine(
        canvas,
        points,
        Color((data['color'] as num?)?.toInt() ?? Colors.white.toARGB32()),
        (data['width'] as num?)?.toDouble() ?? 3,
      );
    }

    _drawLine(canvas, draft, Colors.white, 3);
  }

  void _drawLine(
    Canvas canvas,
    List<Offset> points,
    Color color,
    double width,
  ) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}

class _BoardContentCard extends StatelessWidget {
  const _BoardContentCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final type = (data['type'] ?? '').toString();
    final url = data['url']?.toString() ?? '';
    final name = data['name']?.toString() ?? type;

    if (type == 'image' && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          url,
          width: 130,
          height: 130,
          fit: BoxFit.cover,
        ),
      );
    }

    if (type == 'pdf' && url.isNotEmpty) {
      return SizedBox(
        width: 180,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => RoomDeviceMediaViewer.openOlderPdf(
              context,
              url: url,
              name: name,
            ),
            child: const Center(
              child: Icon(Icons.picture_as_pdf_rounded, size: 48),
            ),
          ),
        ),
      );
    }

    if (type == 'video' && url.isNotEmpty) {
      return SizedBox(
        width: 180,
        child: Card(
          child: InkWell(
            onTap: () => launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            ),
            child: const Center(
              child: Icon(Icons.play_circle_fill_rounded, size: 52),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            (data['text'] ?? name).toString(),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
