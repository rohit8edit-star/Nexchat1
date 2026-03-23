import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class VoiceRecorder extends StatefulWidget {
  final Function(File) onRecorded;

  const VoiceRecorder({super.key, required this.onRecorded});

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  int _seconds = 0;

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(), path: path);
    setState(() {
      _isRecording = true;
      _seconds = 0;
    });

    // Timer
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRecording) return false;
      setState(() => _seconds++);
      return _isRecording;
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);

    if (path != null) {
      widget.onRecorded(File(path));
    }
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red : const Color(0xFF0084FF),
          shape: BoxShape.circle,
        ),
        child: _isRecording
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mic, color: Colors.white, size: 20),
                  const SizedBox(width: 4),
                  Text(_formatDuration(_seconds),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12)),
                ],
              )
            : const Icon(Icons.mic, color: Colors.white, size: 20),
      ),
    );
  }
}
