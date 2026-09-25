import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'board_media_error.dart';

class BoardTextInput extends StatefulWidget {
  const BoardTextInput({required this.onSave, required this.onClose, super.key});
  final Future<void> Function(String) onSave;
  final VoidCallback onClose;
  @override
  State<BoardTextInput> createState() => _BoardTextInputState();
}

class _BoardTextInputState extends State<BoardTextInput> {
  final _controller = TextEditingController();
  bool _saving = false;
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  Future<void> _save(String value) async {
    if (_saving || value.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(value.trim());
      if (mounted) { FocusScope.of(context).unfocus(); widget.onClose(); }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          Localizations.localeOf(context).languageCode == 'ar' ? 'تعذر حفظ النص، حاول مجددًا' : 'Could not save text. Please retry.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller, autofocus: true, enabled: !_saving,
    maxLength: 300, textInputAction: TextInputAction.done, onSubmitted: _save,
    style: const TextStyle(color: Colors.white, fontSize: 18),
    decoration: InputDecoration(counterText: '', filled: true, fillColor: const Color(0xFF164A38),
      hintText: Localizations.localeOf(context).languageCode == 'ar' ? 'اكتب ثم اضغط تم' : 'Type, then press Done',
      suffixIcon: IconButton(onPressed: _saving ? null : () => _save(_controller.text),
        icon: const Icon(Icons.check, color: Color(0xFFE7C56E)))),
  );
}

class BoardVideo extends StatefulWidget {
  const BoardVideo({required this.url, super.key});
  final String url;
  @override
  State<BoardVideo> createState() => _BoardVideoState();
}
class _BoardVideoState extends State<BoardVideo> {
  late VideoPlayerController _player;
  bool _disposed = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _player = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initialize();
  }
  Future<void> _initialize() async {
    try { await _player.initialize(); }
    catch (error) {
      final fallback = compatibleBoardVideoUrl(widget.url);
      if (fallback != null && !_disposed) {
        await _player.dispose();
        if (_disposed) return;
        _player = VideoPlayerController.networkUrl(Uri.parse(fallback));
        try { await _player.initialize(); }
        catch (fallbackError) { _error = '$error\n$fallbackError'; }
      } else { _error = error.toString(); }
    }
    if (mounted) setState(() {});
  }
  @override
  void dispose() { _disposed = true; _player.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    if (_error != null) return BoardMediaError(url: widget.url, error: _error!);
    return ValueListenableBuilder<VideoPlayerValue>(valueListenable: _player,
      builder: (context, value, _) {
        if (value.hasError) return BoardMediaError(url: widget.url, error: value.errorDescription ?? 'Video playback failed');
        if (!value.isInitialized) return const Center(child: CircularProgressIndicator());
        return LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxHeight < 80) {
            return Center(child: IconButton(
              onPressed: () => value.isPlaying ? _player.pause() : _player.play(),
              icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow)));
          }
          return Column(children: [
          Expanded(child: Center(child: AspectRatio(aspectRatio: value.aspectRatio, child: VideoPlayer(_player)))),
          SizedBox(height: 40, child: Row(children: [
            IconButton(tooltip: ar ? 'تشغيل / إيقاف' : 'Play / pause',
              onPressed: () async {
                try {
                  if (value.isPlaying) { await _player.pause(); }
                  else { await _player.play(); }
                } catch (_) { if (mounted) setState(() => _error = 'Video playback failed'); }
              }, icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow)),
            Expanded(child: VideoProgressIndicator(_player, allowScrubbing: true)),
            IconButton(tooltip: ar ? 'صوت الفيديو' : 'Video sound',
              onPressed: () => _player.setVolume(value.volume == 0 ? 1 : 0),
              icon: Icon(value.volume == 0 ? Icons.volume_off : Icons.volume_up)),
          ])),
        ]);
        });
      });
  }
}
