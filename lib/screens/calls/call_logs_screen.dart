import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'call_screen.dart';

class CallLogsScreen extends StatefulWidget {
  const CallLogsScreen({super.key});

  @override
  State<CallLogsScreen> createState() => _CallLogsScreenState();
}

class _CallLogsScreenState extends State<CallLogsScreen> {
  List<dynamic> _callLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCallLogs();
  }

  Future<void> _loadCallLogs() async {
    try {
      final response = await ApiService.getCallLogs();
      setState(() {
        _callLogs = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(String time) {
    try {
      final dt = DateTime.parse(time).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day) {
        return DateFormat('hh:mm a').format(dt);
      }
      return DateFormat('dd MMM').format(dt);
    } catch (e) {
      return '';
    }
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return 'Missed';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}m ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0084FF)))
          : _callLogs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.call_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Koi call nahi hai abhi!',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCallLogs,
                  child: ListView.builder(
                    itemCount: _callLogs.length,
                    itemBuilder: (context, index) {
                      final call = _callLogs[index];
                      final isMissed = call['status'] == 'missed';
                      final isVideo = call['call_type'] == 'video';

                      return Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              radius: 26,
                              backgroundColor: const Color(0xFF0084FF),
                              child: Text(
                                call['other_name'][0].toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                              ),
                            ),
                            title: Text(call['other_name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Row(
                              children: [
                                Icon(
                                  isMissed
                                      ? Icons.call_missed
                                      : Icons.call_received,
                                  size: 14,
                                  color:
                                      isMissed ? Colors.red : Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDuration(call['duration'] ?? 0),
                                  style: TextStyle(
                                      color: isMissed
                                          ? Colors.red
                                          : Colors.grey),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_formatTime(call['created_at']),
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 4),
                                Icon(
                                  isVideo ? Icons.videocam : Icons.call,
                                  color: const Color(0xFF0084FF),
                                  size: 18,
                                ),
                              ],
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CallScreen(
                                  userId: call['caller_id'],
                                  userName: call['other_name'],
                                  isVideo: isVideo,
                                  isIncoming: false,
                                ),
                              ),
                            ),
                          ),
                          const Divider(height: 1, indent: 80),
                        ],
                      );
                    },
                  ),
                ),
    );
  }
}
