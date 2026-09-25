import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'room_board_content.dart';

import '../../../core/media/cloudinary_image_service.dart';
import '../data/room_feature_models.dart';
import '../services/agora_voice_room_controller.dart';
import '../services/room_board_service.dart';
import '../services/room_feature_service.dart';

class RoomBoardScreen extends StatefulWidget {
  const RoomBoardScreen({
    required this.roomId,
    required this.canWrite,
    required this.isHost,
    required this.agoraController,
    this.embedded = false,
    this.onClose,
    this.onExpand,
    super.key,
  });

  final bool embedded;
  final VoidCallback? onClose;
  final VoidCallback? onExpand;
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
  Color _penColor = Colors.white;
  double _penWidth = 3;
  bool _drawing = true;
  bool _boardBusy = false;

  Future<void> _boardAction(Future<void> Function() action) async {
    if (_boardBusy) return;
    setState(() => _boardBusy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          Localizations.localeOf(context).languageCode == 'ar'
            ? 'تعذر حفظ تعديل السبورة. حاول مجددًا.' : 'Board change failed. Please retry.')));
      }
    } finally {
      if (mounted) setState(() => _boardBusy = false);
    }
  }

  Future<void> _penSettings() async {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    await showModalBottomSheet<void>(context: context, useSafeArea: true,
      isScrollControlled: true, showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, update) =>
        SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(ar ? 'لون القلم وسماكته' : 'Pen color and width',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final color in const [Colors.white, Colors.black,
                Color(0xFFE7C56E), Colors.yellow, Colors.orange, Colors.red,
                Colors.pink, Colors.purple, Colors.blue, Colors.cyan,
                Colors.green, Colors.lime])
                Semantics(button: true, selected: _penColor == color,
                  label: '${ar ? 'لون' : 'Color'} ${color.toARGB32().toRadixString(16)}',
                  child: InkWell(onTap: () {
                    setState(() { _penColor = color; _drawing = true; });
                    update(() {});
                  }, child: Container(width: 44, height: 44,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey, width: 2)),
                    child: _penColor == color ? Icon(Icons.check,
                      color: color.computeLuminance() > .5 ? Colors.black : Colors.white) : null))),
            ]),
            const SizedBox(height: 12),
            Row(children: [Text(ar ? 'السماكة' : 'Width'),
              Expanded(child: Slider(value: _penWidth, min: 1, max: 12, divisions: 11,
                label: _penWidth.round().toString(), onChanged: (value) {
                  setState(() => _penWidth = value); update(() {});
                })), Text(_penWidth.round().toString())]),
            Container(height: 24, width: double.infinity, color: const Color(0xFF102C25),
              alignment: Alignment.center, child: Container(height: _penWidth, width: 120, color: _penColor)),
          ])))));
  }

  late final Stream<RoomFeatureState> _stateStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _itemsStream;

  @override
  void initState() {
    super.initState();
    _service = RoomBoardService(roomId: widget.roomId);
    _features = RoomFeatureService(roomId: widget.roomId);
    _stateStream = _features.watchState();
    _itemsStream = _service.watchItems();
  }

  bool _sharingBusy = false;
  Future<void> _toggleScreenShare() async {
    if (_sharingBusy) return;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    setState(() => _sharingBusy = true);
    try {
      final controller = widget.agoraController;
      if (controller.screenSharing) {
        await controller.stopScreenShare();
        await _features.setScreenSharing(active: false);
      } else {
        if (!controller.joined) {
          await controller.ensureConnected(channelId: widget.roomId, role: AgoraRoomRole.speaker);
        }
        await controller.startScreenShare();
        if (!controller.screenSharing || controller.localUid == null) {
          throw StateError(ar ? 'لم تبدأ مشاركة الشاشة' : 'Screen sharing did not start');
        }
        try {
          await _features.setScreenSharing(active: true, sharerUid: controller.localUid!);
        } catch (_) {
          await controller.stopScreenShare();
          rethrow;
        }
      }
    } catch (error) {
      if (mounted) {
        await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
          title: Text(ar ? 'تعذر بدء مشاركة الشاشة' : 'Screen sharing could not start'),
          content: SingleChildScrollView(child: SelectableText(
            '${ar ? 'تفاصيل اتصال Agora:' : 'Agora connection details:'}\n\n$error')),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text(ar ? 'إغلاق' : 'Close'))],
        ));
      }
    } finally {
      if (mounted) setState(() => _sharingBusy = false);
    }
  }

  bool _editingText = false;
  String? _selectedContent;
  void _addText() => setState(() { _editingText = true; _drawing = false; });

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
    if (!mounted || picked == null || picked.path == null) return;

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

      await _service.addMedia(
        type: type,
        url: upload.url,
        name: picked.name,
      );
      if (mounted) setState(() { _selectedContent = null; _drawing = false; });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          Localizations.localeOf(context).languageCode == 'ar' ? 'تعذر رفع الملف، حاول مجددًا' : 'Upload failed. Please retry.')));
      }
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
      colorValue: _penColor.toARGB32(),
      width: _penWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    final board = StreamBuilder<RoomFeatureState>(
        stream: _stateStream,
        builder: (context, featureSnapshot) {
          final featureState = featureSnapshot.data;
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _itemsStream,
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ??
                  const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          final strokes = docs
              .where((doc) => doc.data()['type'] == 'stroke')
              .toList(growable: false);
          final content = docs
              .where((doc) => doc.data()['type'] != 'stroke')
              .toList(growable: false);

          final selected = content.where((doc) => doc.id == _selectedContent).firstOrNull
              ?? (content.isEmpty ? null : content.last);
          return Column(
            children: [
              if (featureState?.screenShareActive == true)
                Expanded(child: _LiveScreenShare(
                  roomId: widget.roomId,
                  sharerUid: featureState?.screenSharerUid,
                  controller: widget.agoraController,
                )),
              if (featureState?.screenShareActive != true) Expanded(
                flex: featureState?.screenShareActive == true ? 3 : 5,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );

                    return ClipRect(child: Stack(fit: StackFit.expand, children: [
                      if (selected != null) _BoardContentCard(key: ValueKey(selected.id), data: selected.data()),
                      if (_editingText) Align(alignment: Alignment.topCenter,
                        child: BoardTextInput(onSave: _service.addText,
                          onClose: () => setState(() { _editingText = false; _selectedContent = null; }))),
                      IgnorePointer(ignoring: !_drawing || _editingText, child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: widget.canWrite && _drawing && !_boardBusy
                          ? (details) {
                              _draft
                                ..clear()
                                ..add(details.localPosition);
                              setState(() {});
                            }
                          : null,
                      onPanUpdate: widget.canWrite && _drawing && !_boardBusy
                          ? (details) {
                              _draft.add(details.localPosition);
                              setState(() {});
                            }
                          : null,
                      onPanEnd: widget.canWrite && _drawing && !_boardBusy
                          ? (_) => _boardAction(() => _saveStroke(size))
                          : null,
                      child: CustomPaint(
                        foregroundPainter: _BoardPainter(
                          strokes: strokes,
                          draft: _draft,
                          draftColor: _penColor,
                          draftWidth: _penWidth,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected == null && !_editingText ? const Color(0xFF102C25) : Colors.transparent,
                            border: Border.all(color: Colors.white12),
                          ),
                        ),
                      ),
                    )),
                    ]));
                  },
                ),
              ),
              if (content.isNotEmpty && !_editingText)
                SizedBox(height: 32, child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final doc in content) Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(label: Text((doc.data()['name'] ?? doc.data()['text'] ?? doc.data()['type']).toString(),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                      onPressed: () => setState(() { _selectedContent = doc.id; _drawing = false; }))),
                ])),
              SizedBox(height: 48, child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  if (widget.isHost) IconButton(tooltip: isArabic ? 'مشاركة الشاشة / إيقاف' : 'Start / stop screen sharing',
                    onPressed: _sharingBusy ? null : _toggleScreenShare,
                    icon: Icon(widget.agoraController.screenSharing ? Icons.stop_screen_share : Icons.screen_share)),
                  if (widget.canWrite) ...[
                    IconButton(tooltip: isArabic ? 'ألوان القلم والسماكة' : 'Pen colors and width',
                      onPressed: _boardBusy ? null : _penSettings,
                      icon: Icon(Icons.palette, color: _penColor)),
                    IconButton(tooltip: isArabic ? 'الرسم' : 'Draw',
                      onPressed: () => setState(() => _drawing = !_drawing),
                      icon: Icon(_drawing ? Icons.edit : Icons.pan_tool_outlined)),
                    IconButton(tooltip: isArabic ? 'تراجع عن رسمك' : 'Undo your stroke',
                      onPressed: _boardBusy || !strokes.any((doc) => doc.data()['userId'] == _service.currentUserId)
                        ? null : () => _boardAction(_service.undoStroke), icon: const Icon(Icons.undo)),
                    IconButton(tooltip: isArabic ? 'إعادة رسمك' : 'Redo your stroke',
                      onPressed: _boardBusy || !_service.canRedo ? null : () => _boardAction(_service.redoStroke),
                      icon: const Icon(Icons.redo)),
                    IconButton(tooltip: isArabic ? 'نص' : 'Text', onPressed: _addText, icon: const Icon(Icons.text_fields)),
                    IconButton(tooltip: isArabic ? 'صورة' : 'Image', onPressed: _uploading ? null : () => _pickAndUpload('image'), icon: const Icon(Icons.image_outlined)),
                    IconButton(tooltip: isArabic ? 'فيديو' : 'Video', onPressed: _uploading ? null : () => _pickAndUpload('video'), icon: const Icon(Icons.video_file_outlined)),
                    IconButton(tooltip: 'PDF', onPressed: _uploading ? null : () => _pickAndUpload('pdf'), icon: const Icon(Icons.folder_open)),
                  ],
                  if (widget.isHost) IconButton(tooltip: isArabic ? 'مسح' : 'Clear', onPressed: _boardBusy ? null : () => _boardAction(_service.clear), icon: const Icon(Icons.delete_outline)),
                ]),
              )),
            ],
          );
            },
          );
        },
    );
    return Theme(
      data: Theme.of(context).copyWith(
        iconTheme: const IconThemeData(color: Color(0xFFE7C56E))),
      child: widget.embedded
        ? ColoredBox(color: const Color(0xFF102C25), child: Column(children: [
            SizedBox(height: 36, child: Row(children: [
              IconButton(padding: EdgeInsets.zero, tooltip: isArabic ? 'تكبير' : 'Expand', onPressed: widget.onExpand, icon: const Icon(Icons.fullscreen)),
              Expanded(child: Text(isArabic ? 'السبورة المشتركة' : 'Shared board', style: const TextStyle(color: Color(0xFFE7C56E), fontSize: 12))),
              IconButton(padding: EdgeInsets.zero, tooltip: isArabic ? 'إخفاء السبورة' : 'Hide board', onPressed: widget.onClose, icon: const Icon(Icons.close)),
            ])),
            Expanded(child: board),
          ]))
        : Scaffold(backgroundColor: const Color(0xFF102C25),
            appBar: AppBar(title: Text(isArabic ? 'السبورة المشتركة' : 'Shared board')),
            body: board),
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
      height: 220,
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: isLocal
          ? const Center(
              child: Text(
                'Your screen is live',
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
    required this.draftColor,
    required this.draftWidth,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> strokes;
  final List<Offset> draft;
  final Color draftColor;
  final double draftWidth;

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

    _drawLine(canvas, draft, draftColor, draftWidth);
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
  const _BoardContentCard({required this.data, super.key});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final type = data['type'];
    final url = data['url']?.toString() ?? '';
    if (type == 'image' && url.isNotEmpty) {
      return Image.network(url, fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image_outlined)));
    }
    if (type == 'video' && url.isNotEmpty) return BoardVideo(key: ValueKey(url), url: url);
    if (type == 'pdf' && url.isNotEmpty) return PdfViewer.uri(Uri.parse(url));
    return SingleChildScrollView(padding: const EdgeInsets.all(12),
      child: Text(data['text']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 20)));
  }
}
