import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userAvatar;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupSocket();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    _myUserId = prefs.getString('userId');

    try {
      final response = await ApiService.getMessages(widget.userId);
      setState(() {
        _messages = (response.data as List).map((m) => MessageModel.fromJson(m)).toList();
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
      if ((message.senderId == widget.userId && message.receiverId == _myUserId) ||
          (message.senderId == _myUserId && message.receiverId == widget.userId)) {
        setState(() => _messages.add(message));
        _scrollToBottom();
      }
    });

    SocketService.onTyping((data) {
      if (data['sender_id'] == widget.userId) {
        setState(() => _isTyping = true);
      }
    });

    SocketService.onStopTyping((data) {
      if (data['sender_id'] == widget.userId) {
        setState(() => _isTyping = false);
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

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    final content = _messageController.text.trim();
    _messageController.clear();

    SocketService.sendMessage({
      'sender_id': _myUserId,
      'receiver_id': widget.userId,
      'content': content,
      'message_type': 'text',
    });

    SocketService.emitStopTyping(_myUserId!, widget.userId);
  }

  void _deleteMessage(String messageId) {
    SocketService.deleteMessage(messageId, widget.userId);
    setState(() {
      final index = _messages.indexWhere((m) => m.id == messageId);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A884),
        foregroundColor: Colors.white,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              backgroundImage: widget.userAvatar != null
                  ? NetworkImage('https://api.webzet.store${widget.userAvatar}')
                  : null,
              child: widget.userAvatar == null
                  ? Text(widget.userName[0].toUpperCase(),
                      style: const TextStyle(color: Color(0xFF00A884)))
                  : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (_isTyping)
                  const Text('typing...', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A884)))
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
    return GestureDetector(
      onLongPress: isMe && !message.isDeleted
          ? () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Message delete karo?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        _deleteMessage(message.id);
                        Navigator.pop(context);
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              )
          : null,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: message.isDeleted
                ? Colors.grey[300]
                : isMe
                    ? const Color(0xFFDCF8C6)
                    : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(isMe ? 12 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 12),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1)),
            ],
          ),
          child: message.isDeleted
              ? const Text('🚫 Message delete ho gaya', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
              : Text(message.content ?? '', style: const TextStyle(fontSize: 15)),
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    SocketService.emitTyping(_myUserId!, widget.userId);
                  } else {
                    SocketService.emitStopTyping(_myUserId!, widget.userId);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF00A884),
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
