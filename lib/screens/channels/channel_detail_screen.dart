import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class ChannelDetailScreen extends StatefulWidget {
  final String channelId;
  final String channelName;

  const ChannelDetailScreen({
    super.key,
    required this.channelId,
    required this.channelName,
  });

  @override
  State<ChannelDetailScreen> createState() => _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends State<ChannelDetailScreen> {
  List<dynamic> _posts = [];
  bool _isLoading = true;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final response = await ApiService.getChannelPosts(widget.channelId);
      setState(() {
        _posts = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSubscribe() async {
    try {
      final response = await ApiService.subscribeChannel(widget.channelId);
      setState(() => _isSubscribed = response.data['subscribed']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSubscribed ? 'Subscribed! ✅' : 'Unsubscribed!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  String _formatTime(String time) {
    try {
      final dt = DateTime.parse(time).toLocal();
      return DateFormat('dd MMM, hh:mm a').format(dt);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0084FF),
        foregroundColor: Colors.white,
        title: Text(widget.channelName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _toggleSubscribe,
            child: Text(
              _isSubscribed ? 'Subscribed ✅' : 'Subscribe',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0084FF)))
          : _posts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign_outlined,
                          size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Koi post nahi hai abhi!',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFF0084FF),
                                  child: Text(
                                    widget.channelName[0].toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.channelName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(_formatTime(post['created_at']),
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(post['content'] ?? '',
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.remove_red_eye_outlined,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('${post['views']} views',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
