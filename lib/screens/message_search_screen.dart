import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class MessageSearchScreen extends StatefulWidget {
  const MessageSearchScreen({super.key});

  @override
  State<MessageSearchScreen> createState() => _MessageSearchScreenState();
}

class _MessageSearchScreenState extends State<MessageSearchScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.searchMessages(query);
      setState(() => _results = response.data);
    } catch (e) {
      setState(() => _results = []);
    }
    setState(() => _isLoading = false);
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
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Messages search karo...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0084FF)))
          : _results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'Kuch search karo'
                            : 'Koi message nahi mila',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final msg = _results[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF0084FF),
                        child: Text(
                          msg['sender_name'][0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(msg['sender_name'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        msg['content'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _formatTime(msg['created_at']),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    );
                  },
                ),
    );
  }
}
