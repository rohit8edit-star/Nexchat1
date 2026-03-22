import 'package:flutter/material.dart';
import '../../services/socket_service.dart';

class CallScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userAvatar;
  final bool isVideo;
  final bool isIncoming;
  final dynamic offer;

  const CallScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.isVideo,
    required this.isIncoming,
    this.offer,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isMuted = false;
  bool _isSpeaker = false;
  bool _isConnected = false;
  int _duration = 0;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _setupCall();
  }

  void _setupCall() {
    SocketService.onCallAnswered((_) {
      setState(() => _isConnected = true);
      _startTimer();
    });

    SocketService.onCallRejected((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Call reject ho gaya!')),
        );
        Navigator.pop(context);
      }
    });

    SocketService.onCallEnded((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _duration++);
      return _isConnected;
    });
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _endCall() {
    SocketService.endCall(widget.userId,
        widget.isVideo ? 'video' : 'voice', _duration);
    Navigator.pop(context);
  }

  void _answerCall() {
    SocketService.answerCall(widget.userId, null);
    setState(() => _isConnected = true);
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFF0084FF),
                    child: Text(
                      widget.userName[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 48,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isConnected
                        ? _formatDuration(_duration)
                        : widget.isIncoming
                            ? widget.isVideo
                                ? 'Video call aa rahi hai...'
                                : 'Voice call aa rahi hai...'
                            : 'Ringing...',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    widget.isVideo ? Icons.videocam : Icons.call,
                    color: Colors.white54,
                    size: 24,
                  ),
                ],
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(32),
              child: widget.isIncoming && !_isConnected
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Reject
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.red,
                              child: IconButton(
                                icon: const Icon(Icons.call_end,
                                    color: Colors.white, size: 30),
                                onPressed: () {
                                  SocketService.rejectCall(widget.userId);
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('Decline',
                                style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        // Accept
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.green,
                              child: IconButton(
                                icon: const Icon(Icons.call,
                                    color: Colors.white, size: 30),
                                onPressed: _answerCall,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('Accept',
                                style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Mute
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: _isMuted
                                  ? Colors.white
                                  : Colors.white24,
                              child: IconButton(
                                icon: Icon(
                                  _isMuted ? Icons.mic_off : Icons.mic,
                                  color: _isMuted
                                      ? Colors.black
                                      : Colors.white,
                                ),
                                onPressed: () =>
                                    setState(() => _isMuted = !_isMuted),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(_isMuted ? 'Unmute' : 'Mute',
                                style:
                                    const TextStyle(color: Colors.white70)),
                          ],
                        ),
                        // End call
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.red,
                              child: IconButton(
                                icon: const Icon(Icons.call_end,
                                    color: Colors.white, size: 30),
                                onPressed: _endCall,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('End',
                                style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        // Speaker
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: _isSpeaker
                                  ? Colors.white
                                  : Colors.white24,
                              child: IconButton(
                                icon: Icon(
                                  _isSpeaker
                                      ? Icons.volume_up
                                      : Icons.volume_down,
                                  color: _isSpeaker
                                      ? Colors.black
                                      : Colors.white,
                                ),
                                onPressed: () =>
                                    setState(() => _isSpeaker = !_isSpeaker),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('Speaker',
                                style: TextStyle(color: Colors.white70)),
                          ],
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
