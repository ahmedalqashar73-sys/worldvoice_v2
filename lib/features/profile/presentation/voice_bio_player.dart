import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/localization/app_strings.dart';

class VoiceBioPlayer extends StatefulWidget {
  const VoiceBioPlayer({
    required this.url,
    required this.code,
    this.compact = false,
    super.key,
  });

  final String url;
  final String code;
  final bool compact;

  @override
  State<VoiceBioPlayer> createState() => _VoiceBioPlayerState();
}

class _VoiceBioPlayerState extends State<VoiceBioPlayer> {
  final AudioPlayer _player = AudioPlayer();
  String? _loadedUrl;
  bool _loading = false;

  @override
  void didUpdateWidget(covariant VoiceBioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loadedUrl = null;
      _player.stop();
    }
  }

  Future<void> _toggle() async {
    if (_loading) return;

    try {
      if (_player.playing) {
        await _player.pause();
        return;
      }

      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }

      if (_loadedUrl != widget.url) {
        setState(() => _loading = true);
        await _player.setUrl(widget.url);
        _loadedUrl = widget.url;
      }

      await _player.play();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.of(widget.code).profile('voiceSaveFailed'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(widget.code);

    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final playing = state?.playing == true &&
            state?.processingState != ProcessingState.completed;

        if (widget.compact) {
          return IconButton.filledTonal(
            onPressed: _loading ? null : _toggle,
            tooltip: playing
                ? strings.profile('pauseVoiceIntro')
                : strings.profile('playVoiceIntro'),
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
          );
        }

        return OutlinedButton.icon(
          onPressed: _loading ? null : _toggle,
          icon: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
          label: Text(
            playing
                ? strings.profile('pauseVoiceIntro')
                : strings.profile('playVoiceIntro'),
          ),
        );
      },
    );
  }
}
