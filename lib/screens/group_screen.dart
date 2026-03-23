import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/message_model.dart';
import 'create_poll_screen.dart';

class GroupScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupSocket();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    _myUserId = prefs.getString('userId');
    SocketService.joinRoom(widget.groupId);

    try {
      final response = await ApiService.getGroupMessages(widget.groupId);
      setState(() {
        _messages = (response.data as List)
            .map((m) => MessageModel.fromJson(m))
            .toList();
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _setupSocket() {
    SocketService.onNewMessage((data) {
      final message = MessageModel.fromJson(data);
      if (message.groupId == widget.groupId) {
        if (!_messages.any((m) => m.id == message.id)) {
          setState(() => _messages.add(message));
          _scrollToBottom();
        }
      }
    });

    SocketService.onMessageDeleted((data) {
      setState(() {
        final index = _messages.indexWhere((m) => m.id == data['message_id']);
        if (index != -1) {
          _messages[index] = MessageModel(
            id: _messages[index].id,
            senderId: _messages[index].senderId,
            messageType: _messages[index].messageType,
            isDeleted: true,
            isRead: _messages[index].isRead,
            createdAt: _messages[index].createdAt,
          );
        }
      });
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return '';
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    final content = _messageController.text.trim();
    _messageController.clear();

    SocketService.sendMessage({
      'sender_id': _myUserId,
      'group_id': widget.groupId,
      'content': content,
      'message_type': 'text',
    });
  }

  void _showMembers() async {
    final members = await ApiService.getGroupMembers(widget.groupId);
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Group Members'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: members.data.length,
              itemBuilder: (context, index) {
                final member = members.data[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF0084FF),
                    child: Text(member['name'][0].toUpperCase(),
                        style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(member['name']),
                  subtitle: Text(member['phone']),
                  trailing: member['is_admin']
                      ? const Chip(
                          label: Text('Admin'),
                          backgroundColor: Color(0xFF0084FF),
                          labelStyle: TextStyle(color: Colors.white),
                        )
                      : null,
                );
              },
            ),
          ),
          actions: [
          IconButton(
            icon: const Icon(Icons.poll),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreatePollScreen(groupId: widget.groupId),
              ),
            ),
          ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0084FF),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Text(widget.groupName[0].toUpperCase(),
                  style: const TextStyle(
                      color: Color(0xFF0084FF),
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.groupName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const Text('Group',
                    style:
                        TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.poll),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreatePollScreen(groupId: widget.groupId),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: _showMembers,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF0084FF)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderId == _myUserId;
                      return _buildMessageBubble(message, isMe);
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isDeleted
              ? Colors.grey[300]
              : isMe
                  ? const Color(0xFF0084FF)
                  : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 18),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 3,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe && message.senderName != null)
              Text(message.senderName!,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            message.isDeleted
                ? const Text('🚫 Message delete ho gaya',
                    style: TextStyle(
                        color: Colors.grey, fontStyle: FontStyle.italic))
                : Text(message.content ?? '',
                    style: TextStyle(
                        fontSize: 15,
                        color: isMe ? Colors.white : Colors.black87)),
            const SizedBox(height: 2),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Message likho...',
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF0084FF),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
