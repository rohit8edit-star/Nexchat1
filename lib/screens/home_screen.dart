import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../widgets/chat_list_tile.dart';
import 'chat_screen.dart';
import 'group_screen.dart';
import 'search_screen.dart';
import 'message_search_screen.dart';
import 'profile/profile_screen.dart';
import 'status/status_screen.dart';
import 'channels/channels_screen.dart';
import 'calls/call_logs_screen.dart';
import 'calls/call_screen.dart';
import 'ai_screen.dart';
import 'create_group_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _chats = [];
  List<dynamic> _groups = [];
  Map<String, int> _unreadCounts = {};
  bool _isLoading = true;
  String? _userId;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
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

    SocketService.onIncomingCall((data) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text('${data['caller_name']} ka call!'),
          content: Text(data['call_type'] == 'video'
              ? '📹 Video Call'
              : '📞 Voice Call'),
          actions: [
            TextButton(
              onPressed: () {
                SocketService.rejectCall(data['caller_id']);
                Navigator.pop(context);
              },
              child: const Text('Decline',
                  style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CallScreen(
                      userId: data['caller_id'],
                      userName: data['caller_name'],
                      isVideo: data['call_type'] == 'video',
                      isIncoming: true,
                      offer: data['offer'],
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white),
              child: const Text('Accept'),
            ),
          ],
        ),
      );
    });
  }

  void _showNewChatOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF0084FF),
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: const Text('New Chat'),
              subtitle: const Text('Kisi se baat karo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SearchScreen()))
                    .then((_) => _loadData());
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF0066CC),
                child: Icon(Icons.group, color: Colors.white),
              ),
              title: const Text('New Group'),
              subtitle: const Text('Group banao'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateGroupScreen()))
                    .then((_) => _loadData());
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: const Color(0xFF0084FF),
              foregroundColor: Colors.white,
              title: const Text('NexChat',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 22)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MessageSearchScreen())),
                ),
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen())),
                ),
              ],
            )
          : null,
      body: _selectedIndex == 0
          ? _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF0084FF)))
              : _buildChatList()
          : [
              const SizedBox(),
              const StatusScreen(),
              const ChannelsScreen(),
              const CallLogsScreen(),
              const AiScreen(),
            ][_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0084FF),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.chat),
                if (_unreadCounts.values.fold(0, (a, b) => a + b) > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: Text(
                        _unreadCounts.values
                            .fold(0, (a, b) => a + b)
                            .toString(),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Chats',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.circle_outlined),
            label: 'Status',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            label: 'Channels',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.call_outlined),
            label: 'Calls',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Nex AI',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF0084FF),
              foregroundColor: Colors.white,
              onPressed: _showNewChatOptions,
              child: const Icon(Icons.chat),
            )
          : null,
    );
  }

  Widget _buildChatList() {
    final allChats = [..._chats, ..._groups];

    if (allChats.isEmpty) {
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
        itemCount: allChats.length,
        itemBuilder: (context, index) {
          final chat = allChats[index];
          final isGroup = index >= _chats.length;
          final unread = isGroup ? 0 : (_unreadCounts[chat['id']] ?? 0);

          return ChatListTile(
            chat: chat,
            isGroup: isGroup,
            unreadCount: unread,
            onRefresh: _loadData,
            onTap: () {
              if (isGroup) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupScreen(
                        groupId: chat['id'],
                        groupName: chat['name']),
                  ),
                ).then((_) => _loadData());
              } else {
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
              }
            },
          );
        },
      ),
    );
  }
}
