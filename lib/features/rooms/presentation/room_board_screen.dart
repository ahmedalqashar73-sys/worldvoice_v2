import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/media/cloudinary_image_service.dart';
import '../data/room_feature_models.dart';
import '../services/agora_voice_room_controller.dart';
import '../services/board_media_cache.dart';
import '../services/room_board_service.dart';
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
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _service = RoomBoardService(roomId: widget.roomId);
    _features = RoomFeatureService(roomId: widget.roomId);
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

  Future<void> _pickAndUpload(String type) async {
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
    if (picked == null || picked.path == null) return;

    setState(() => _uploading = true);
    try {
      final file = File(picked.path!);
      final folder = 'worldvoice/rooms/${widget.roomId}/board';
      final upload = switch (type) {
        'image' => await CloudinaryImageService.uploadImage(
            file,
            folder: folder,
          ),
        'video' => await CloudinaryImageService.uploadVideo(
            file,
            folder: folder,
          ),
        'pdf' => await CloudinaryImageService.uploadRaw(
            file,
            folder: folder,
          ),
        _ => throw StateError('Unsupported board media'),
      };

      // Keep the original file on the owner's device. Other participants
      // download and cache from the shared URL only when they open it.
      try {
        await BoardMediaCache.rememberLocalCopy(
          url: upload.url,
          type: type,
          source: file,
        );
      } catch (_) {
        // A cache failure must not discard a successfully uploaded board item.
      }
      await _service.addMedia(
        type: type,
        url: upload.url,
        name: picked.name,
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
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
              // The owner should not recursively preview their own screen.
              // Viewers receive a full-size video area instead of a 220px tile.
              if (featureState?.screenShareActive == true &&
                  featureState?.screenSharerUid ==
                      widget.agoraController.localUid)
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Text(
                    'Your screen is live to room participants.',
                    textAlign: TextAlign.center,
                  ),
                ),
              if (featureState?.screenShareActive == true &&
                  featureState?.screenSharerUid !=
                      widget.agoraController.localUid)
                Expanded(
                  child: _LiveScreenShare(
                    roomId: widget.roomId,
                    sharerUid: featureState?.screenSharerUid,
                    controller: widget.agoraController,
                  ),
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
              if (featureState?.screenShareActive != true ||
                  featureState?.screenSharerUid ==
                      widget.agoraController.localUid)
              Expanded(
                flex: 5,
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
                              _uploading ? null : () => _pickAndUpload('image'),
                          icon: const Icon(Icons.image_rounded),
                          label: Text(isArabic ? 'صورة' : 'Image'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed:
                              _uploading ? null : () => _pickAndUpload('video'),
                          icon: const Icon(Icons.video_file_rounded),
                          label: Text(isArabic ? 'فيديو' : 'Video'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed:
                              _uploading ? null : () => _pickAndUpload('pdf'),
                          icon: const Icon(Icons.picture_as_pdf_rounded),
                          label: const Text('PDF'),
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
    final engine = controller.engine;
    if (uid == null || engine == null) {
      return const SizedBox.shrink();
    }

    final isLocal = uid == controller.localUid;
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: isLocal
          ? const Center(
              child: Text(
                'Your screen is live to room participants.',
                style: TextStyle(color: Colors.white),
              ),
            )
          : AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: engine,
                canvas: VideoCanvas(
                  uid: uid,
                  sourceType: VideoSourceType.videoSourceRemote,
                ),
                connection: RtcConnection(channelId: roomId),
              ),
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
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _CachedPdfPage(name: name, url: url),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.picture_as_pdf_rounded, size: 45),
                const SizedBox(height: 4),
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
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
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                const SnackBar(content: Text('Opening saved video…')),
              );
              try {
                final file = await BoardMediaCache.getFile(url, 'video');
                final opened = await launchUrl(
                  Uri.file(file.path),
                  mode: LaunchMode.externalApplication,
                );
                if (!opened) throw StateError('No local video player available.');
              } catch (error) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Cannot open video: $error')),
                );
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_fill_rounded, size: 48),
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
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

class _CachedPdfPage extends StatefulWidget {
  const _CachedPdfPage({required this.name, required this.url});

  final String name;
  final String url;

  @override
  State<_CachedPdfPage> createState() => _CachedPdfPageState();
}

class _CachedPdfPageState extends State<_CachedPdfPage> {
  late Future<File> _file;

  @override
  void initState() {
    super.initState();
    _file = BoardMediaCache.getFile(widget.url, 'pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: FutureBuilder<File>(
        future: _file,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // Load pages from persistent phone storage, avoiding repeat
            // Cloudinary network PDF requests and endless network spinners.
            return PdfViewer.file(snapshot.data!.path);
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 40),
                  const SizedBox(height: 12),
                  const Text('Could not download this PDF.'),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => setState(() {
                      _file = BoardMediaCache.getFile(widget.url, 'pdf');
                    }),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Saving PDF to this phone…'),
              ],
            ),
          );
        },
      ),
    );
  }
}
