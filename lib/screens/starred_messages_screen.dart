import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class StarredMessagesScreen extends StatefulWidget {
  const StarredMessagesScreen({super.key});

  @override
  State<StarredMessagesScreen> createState() => _StarredMessagesScreenState();
}

class _StarredMessagesScreenState extends State<StarredMessagesScreen> {
  List<dynamic> _starred = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStarred();
  }

  Future<void> _loadStarred() async {
    try {
      final response = await ApiService.getStarredMessages();
      setState(() {
        _starred = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
        title: const Text('Starred Messages'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0084FF)))
          : _starred.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_border, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Koi starred message nahi!',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                      Text('Messages pe long press karke star karo',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _starred.length,
                  itemBuilder: (context, index) {
                    final msg = _starred[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF0084FF),
                          child: Text(
                            msg['sender_name'][0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(msg['sender_name'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          msg['content'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            Text(_formatTime(msg['created_at']),
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
