import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'chat_screen.dart';
import 'group_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _chats = [];
  List<dynamic> _groups = [];
  Map<String, int> _unreadCounts = {};
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');

    if (_userId != null) {
      SocketService.connect(_userId!);
      _setupSocket();
    }

    try {
      final chatsResponse = await ApiService.getChats();
      final groupsResponse = await ApiService.getGroups();

      // Get unread counts
      if (_userId != null) {
        final unreadResponse = await ApiService.getUnreadCounts(_userId!);
        final unreadData = unreadResponse.data as List;
        final Map<String, int> counts = {};
        for (var item in unreadData) {
          counts[item['sender_id']] = int.parse(item['count'].toString());
        }
        setState(() => _unreadCounts = counts);
      }

      setState(() {
        _chats = chatsResponse.data;
        _groups = groupsResponse.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _setupSocket() {
    SocketService.onNewMessage((data) {
      if (data['receiver_id'] == _userId) {
        setState(() {
          final senderId = data['sender_id'];
          _unreadCounts[senderId] = (_unreadCounts[senderId] ?? 0) + 1;
        });
        _loadData();
      }
    });
  }

  String _formatTime(String? time) {
    if (time == null) return '';
    try {
      final dt = DateTime.parse(time).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return DateFormat('hh:mm a').format(dt);
      }
      return DateFormat('dd/MM/yy').format(dt);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0084FF),
        foregroundColor: Colors.white,
        title: const Text('NexChat',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'CHATS'),
            Tab(text: 'GROUPS'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0084FF)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildChatList(),
                _buildGroupList(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0084FF),
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SearchScreen())),
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget _buildChatList() {
    if (_chats.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Koi chat nahi hai abhi!',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            Text('Search karke kisi se baat karo',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          final unread = _unreadCounts[chat['id']] ?? 0;
          return Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF0084FF),
                  backgroundImage: chat['avatar'] != null
                      ? NetworkImage(
                          'https://api.webzet.store${chat['avatar']}')
                      : null,
                  child: chat['avatar'] == null
                      ? Text(chat['name'][0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18))
                      : null,
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(chat['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      _formatTime(chat['created_at']),
                      style: TextStyle(
                        fontSize: 12,
                        color: unread > 0
                            ? const Color(0xFF0084FF)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        chat['content'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unread > 0 ? Colors.black87 : Colors.grey,
                          fontWeight: unread > 0
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (unread > 0)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0084FF),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unread.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  setState(() => _unreadCounts[chat['id']] = 0);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        userId: chat['id'],
                        userName: chat['name'],
                        userAvatar: chat['avatar'],
                      ),
                    ),
                  ).then((_) => _loadData());
                },
              ),
              const Divider(height: 1, indent: 80),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupList() {
    if (_groups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Koi group nahi hai abhi!',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF0066CC),
                  child: Text(group['name'][0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ),
                title: Text(group['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  group['last_message'] ?? 'Group banaya gaya',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: Text(
                  _formatTime(group['last_message_time']),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupScreen(
                      groupId: group['id'],
                      groupName: group['name'],
                    ),
                  ),
                ).then((_) => _loadData()),
              ),
              const Divider(height: 1, indent: 80),
            ],
          );
        },
      ),
    );
  }
}
