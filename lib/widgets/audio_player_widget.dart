import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String url;
  final bool isMe;

  const AudioPlayerWidget({
    super.key,
    required this.url,
    required this.isMe,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _player.onPlayerComplete.listen((_) => setState(() {
      _isPlaying = false;
      _position = Duration.zero;
    }));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      await _player.play(UrlSource('https://api.webzet.store${widget.url}'));
      setState(() => _isPlaying = true);
    }
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _togglePlay,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: widget.isMe
                ? Colors.white.withValues(alpha: 0.3)
                : const Color(0xFF0084FF),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SliderTheme(
                data: SliderThemeData(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  trackHeight: 3,
                  thumbColor: widget.isMe ? Colors.white : const Color(0xFF0084FF),
                  activeTrackColor: widget.isMe ? Colors.white : const Color(0xFF0084FF),
                  inactiveTrackColor: widget.isMe
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.grey[300],
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: _duration.inSeconds > 0
                      ? _position.inSeconds / _duration.inSeconds
                      : 0,
                  onChanged: (value) async {
                    final position = Duration(
                        seconds: (value * _duration.inSeconds).round());
                    await _player.seek(position);
                  },
                ),
              ),
              Text(
                '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                style: TextStyle(
                  fontSize: 10,
                  color: widget.isMe ? Colors.white70 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
