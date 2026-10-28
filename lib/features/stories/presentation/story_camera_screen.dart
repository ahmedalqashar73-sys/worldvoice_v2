import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../services/story_filter_presets.dart';

class StoryCapture {
  const StoryCapture(this.file, this.filter);
  final XFile file;
  final StoryPhotoFilter filter;
}

/// Capture stays local until the user confirms publication in the editor.
class StoryCameraScreen extends StatefulWidget {
  const StoryCameraScreen({
    required this.isArabic,
    required this.video,
    super.key,
  });
  final bool isArabic;
  final bool video;

  @override
  State<StoryCameraScreen> createState() => _StoryCameraScreenState();
}

class _StoryCameraScreenState extends State<StoryCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  List<CameraDescription> _cameras = [];
  int _lens = 0;
  int _epoch = 0;
  bool _busy = false;
  bool _active = true;
  bool _recording = false;
  bool _flash = false;
  String? _error;
  int _seconds = 0;
  Timer? _clock;
  StoryPhotoFilter _filter = StoryPhotoFilter.original;
  Future<void> _release = Future<void>.value();
  bool get ar => widget.isArabic;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_openCamera());
  }

  Future<void> _openCamera() async {
    final epoch = ++_epoch;
    setState(() {
      _busy = true;
      _error = null;
    });
    _release = _release.then((_) => _initializeCamera(epoch));
    return _release;
  }

  Future<void> _initializeCamera(int epoch) async {
    if (!mounted || !_active || epoch != _epoch) return;
    CameraController? controller;
    try {
      final old = _camera;
      _camera = null;
      await old?.dispose();
      if (!mounted || !_active || epoch != _epoch) return;
      if (_cameras.isEmpty) _cameras = await availableCameras();
      if (_cameras.isEmpty) throw StateError('No camera');
      if (!mounted || !_active || epoch != _epoch) return;
      controller = CameraController(
        _cameras[_lens % _cameras.length],
        ResolutionPreset.high,
        enableAudio: widget.video,
      );
      await controller.initialize();
      // Some front cameras do not support flash; capture should still work.
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {}
      if (!mounted || !_active || epoch != _epoch) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _flash = false;
      });
    } catch (_) {
      try {
        await controller?.dispose();
      } catch (_) {}
      if (mounted && epoch == _epoch) {
        setState(
          () => _error = ar
              ? 'تعذر فتح الكاميرا. اسمح بالوصول للكاميرا والميكروفون من إعدادات الجهاز ثم حاول مجددًا.'
              : 'Could not open camera. Allow camera and microphone access in device settings, then retry.',
        );
      }
    } finally {
      if (mounted && epoch == _epoch) setState(() => _busy = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _active = true;
      unawaited(_openCamera());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _active = false;
      ++_epoch;
      _clock?.cancel();
      final camera = _camera;
      _camera = null;
      _release = _release.then((_) async {
        await camera?.dispose();
      });
      if (mounted) {
        setState(() {
          _recording = false;
          _busy = false;
        });
      }
    }
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (_busy || camera == null || !camera.value.isInitialized) return;
    final epoch = _epoch;
    setState(() => _busy = true);
    try {
      if (widget.video && !_recording) {
        await camera.startVideoRecording();
        if (!mounted || epoch != _epoch) return;
        setState(() {
          _recording = true;
          _seconds = 0;
        });
        _clock = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() => _seconds++);
          if (_seconds >= 89) {
            _clock?.cancel();
            unawaited(_capture());
          }
        });
      } else {
        _clock?.cancel();
        final file = widget.video
            ? await camera.stopVideoRecording()
            : await camera.takePicture();
        if (!mounted || epoch != _epoch) return;
        setState(() => _recording = false);
        Navigator.of(context).pop(StoryCapture(file, _filter));
      }
    } catch (_) {
      if (mounted && epoch == _epoch) {
        _clock?.cancel();
        setState(() => _recording = camera.value.isRecordingVideo);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar
                  ? 'تعذر التصوير. حاول مرة أخرى.'
                  : 'Capture failed. Please retry.',
            ),
          ),
        );
      }
    } finally {
      if (mounted && epoch == _epoch) setState(() => _busy = false);
    }
  }

  Future<void> _toggleFlash() async {
    if (_busy || _recording || _camera == null) return;
    final epoch = _epoch;
    setState(() => _busy = true);
    try {
      await _camera!.setFlashMode(_flash ? FlashMode.off : FlashMode.torch);
      if (mounted && epoch == _epoch) setState(() => _flash = !_flash);
    } catch (_) {
      if (mounted && epoch == _epoch) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar
                  ? 'الفلاش غير متاح لهذه الكاميرا'
                  : 'Flash unavailable for this camera',
            ),
          ),
        );
      }
    } finally {
      if (mounted && epoch == _epoch) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    ++_epoch;
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    final camera = _camera;
    if (camera != null) unawaited(camera.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: ar ? 'إغلاق' : 'Close',
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
                Expanded(
                  child: Text(
                    _recording
                        ? '$_seconds / 90'
                        : (ar ? 'كاميرا الستوري' : 'Story camera'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  onPressed: _busy || _recording ? null : _toggleFlash,
                  tooltip: ar ? 'الفلاش' : 'Flash',
                  icon: Icon(
                    _flash ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                            TextButton(
                              onPressed: _busy ? null : _openCamera,
                              child: Text(ar ? 'إعادة المحاولة' : 'Retry'),
                            ),
                          ],
                        ),
                      )
                    : camera?.value.isInitialized == true
                    ? ColorFiltered(
                        colorFilter: ColorFilter.matrix(
                          storyFilterMatrix(_filter),
                        ),
                        child: CameraPreview(camera!),
                      )
                    : const CircularProgressIndicator(color: Colors.white),
              ),
            ),
            SizedBox(
              height: 66,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: StoryPhotoFilter.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final filter = StoryPhotoFilter.values[index];
                  return Center(
                    child: ChoiceChip(
                      selected: filter == _filter,
                      onSelected: _recording || _busy
                          ? null
                          : (_) => setState(() => _filter = filter),
                      label: Text(storyFilterLabel(filter, ar)),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(width: 48),
                  IconButton.filled(
                    onPressed: _busy || camera == null ? null : _capture,
                    tooltip: widget.video
                        ? (ar
                              ? 'بدء أو إيقاف التسجيل'
                              : 'Start or stop recording')
                        : (ar ? 'التقاط صورة' : 'Take photo'),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: widget.video ? Colors.red : Colors.black,
                      padding: const EdgeInsets.all(16),
                    ),
                    iconSize: 42,
                    icon: Icon(_recording ? Icons.stop_rounded : Icons.circle),
                  ),
                  IconButton(
                    onPressed: _busy || _recording || _cameras.length < 2
                        ? null
                        : () {
                            _lens = (_lens + 1) % _cameras.length;
                            unawaited(_openCamera());
                          },
                    tooltip: ar ? 'تبديل الكاميرا' : 'Switch camera',
                    icon: const Icon(
                      Icons.flip_camera_ios_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
