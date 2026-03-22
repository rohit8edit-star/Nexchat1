import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'create_status_screen.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  List<dynamic> _myStatuses = [];
  List<dynamic> _contactStatuses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    try {
      final response = await ApiService.getStatuses();
      setState(() {
        _myStatuses = response.data['myStatuses'];
        _contactStatuses = response.data['contactStatuses'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(String time) {
    try {
      final dt = DateTime.parse(time).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0084FF)))
          : RefreshIndicator(
              onRefresh: _loadStatuses,
              child: ListView(
                children: [
                  // My Status
                  ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFF0084FF),
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 30),
                        ),
                        if (_myStatuses.isEmpty)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF0084FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                      ],
                    ),
                    title: const Text('Meri Status',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      _myStatuses.isEmpty
                          ? 'Status add karo'
                          : 'Aaj ${_myStatuses.length} status',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateStatusScreen()),
                    ).then((_) => _loadStatuses()),
                  ),
                  const Divider(),

                  if (_contactStatuses.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('Recent Updates',
                          style: TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                    ..._contactStatuses.map((status) => ListTile(
                          leading: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF0084FF), width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: const Color(0xFF0084FF),
                              child: Text(
                                status['user_name'][0].toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          title: Text(status['user_name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(_formatTime(status['created_at'])),
                          onTap: () async {
                            await ApiService.viewStatus(status['id']);
                            _showStatus(status);
                          },
                        )),
                  ] else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.circle_outlined,
                                size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Koi status nahi hai abhi!',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0084FF),
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateStatusScreen()),
        ).then((_) => _loadStatuses()),
        child: const Icon(Icons.edit),
      ),
    );
  }

  void _showStatus(dynamic status) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Color(int.parse(
            status['bg_color'].replaceAll('#', '0xFF'))),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                status['user_name'],
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              const SizedBox(height: 16),
              Text(
                status['content'] ?? '',
                style:
                    const TextStyle(color: Colors.white, fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _formatTime(status['created_at']),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
