import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
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
  bool _isOnline = false;
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

    try {
      final response = await ApiService.getMessages(widget.userId);
      setState(() {
        _messages = (response.data as List).map((m) => MessageModel.fromJson(m)).toList();
        _isLoading = false;
      });
      _scrollToBottom();
      // Mark as read
      if (_myUserId != null) {
        SocketService.emitMessageRead(widget.userId, _myUserId!);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _setupSocket() {
    SocketService.onNewMessage((data) {
      final message = MessageModel.fromJson(data);
      if ((message.senderId == widget.userId && message.receiverId == _myUserId) ||
          (message.senderId == _myUserId && message.receiverId == widget.userId)) {
        if (!_messages.any((m) => m.id == message.id)) {
          setState(() => _messages.add(message));
          _scrollToBottom();
          if (message.senderId == widget.userId) {
            SocketService.emitMessageRead(widget.userId, _myUserId!);
          }
        }
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

    SocketService.onUserStatus((data) {
      if (data['userId'] == widget.userId) {
        setState(() => _isOnline = data['status'] == 'online');
      }
    });

    SocketService.onMessagesRead((data) {
      if (data['receiver_id'] == widget.userId) {
        setState(() {
          for (var msg in _messages) {
            if (msg.senderId == _myUserId) {
              // Mark as read
            }
          }
        });
      }
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
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0084FF),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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
                      style: const TextStyle(color: Color(0xFF0084FF), fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  _isTyping ? 'typing...' : _isOnline ? 'Online' : '',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0084FF)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderId == _myUserId;
                      final showDate = index == 0 ||
                          _formatDate(_messages[index].createdAt) !=
                              _formatDate(_messages[index - 1].createdAt);
                      return Column(
                        children: [
                          if (showDate) _buildDateDivider(message.createdAt),
                          _buildMessageBubble(message, isMe),
                        ],
                      );
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  String _formatDate(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return 'Aaj';
      } else if (dt.day == now.day - 1) {
        return 'Kal';
      }
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (e) {
      return '';
    }
  }

  Widget _buildDateDivider(String createdAt) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _formatDate(createdAt),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const Expanded(child: Divider()),
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
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        _deleteMessage(message.id);
                        Navigator.pop(context);
                      },
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
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
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              message.isDeleted
                  ? const Text('🚫 Message delete ho gaya',
                      style: TextStyle(
                          color: Colors.grey, fontStyle: FontStyle.italic))
                  : Text(
                      message.content ?? '',
                      style: TextStyle(
                          fontSize: 15,
                          color: isMe ? Colors.white : Colors.black87),
                    ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: message.isRead ? Colors.white : Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
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
