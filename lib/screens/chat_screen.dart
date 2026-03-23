import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/message_model.dart';
import '../widgets/message_bubble.dart';
import '../widgets/voice_recorder.dart';
import '../widgets/gif_picker.dart';
import '../widgets/link_preview_widget.dart';
import 'chat_wallpaper_screen.dart';
import 'contact_share_screen.dart';

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
  bool _showVoice = true;
  String? _myUserId;
  MessageModel? _replyingTo;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadWallpaper();
    _setupSocket();
    _messageController.addListener(() {
      setState(() => _showVoice = _messageController.text.isEmpty);
    });
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
        _messages = (response.data as List)
            .map((m) => MessageModel.fromJson(m))
            .toList();
        _isLoading = false;
      });
      _scrollToBottom();
      if (_myUserId != null) {
        SocketService.emitMessageRead(widget.userId, _myUserId!);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _wallpaper = prefs.getString('wallpaper_${widget.userId}') ?? 'default');
  }

  Color get _wallpaperColor {
    switch (_wallpaper) {
      case 'blue': return const Color(0xFFE3F2FD);
      case 'green': return const Color(0xFFE8F5E9);
      case 'purple': return const Color(0xFFF3E5F5);
      case 'orange': return const Color(0xFFFFF3E0);
      case 'pink': return const Color(0xFFFCE4EC);
      case 'dark': return const Color(0xFF212121);
      case 'navy': return const Color(0xFF1A237E);
      default: return const Color(0xFFF0F2F5);
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
      if (_replyingTo != null) 'reply_to': _replyingTo!.id,
    });

    setState(() => _replyingTo = null);
    SocketService.emitStopTyping(_myUserId!, widget.userId);
  }

  Future<void> _sendVoice(File file) async {
    try {
      final response = await ApiService.uploadMedia(file, 'audio');
      SocketService.sendMessage({
        'sender_id': _myUserId,
        'receiver_id': widget.userId,
        'content': '🎤 Voice message',
        'message_type': 'audio',
        'media_url': response.data['url'],
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice message send nahi hua!')),
        );
      }
    }
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    try {
      final response = await ApiService.uploadMedia(File(picked.path), 'image');
      SocketService.sendMessage({
        'sender_id': _myUserId,
        'receiver_id': widget.userId,
        'content': '📷 Photo',
        'message_type': 'image',
        'media_url': response.data['url'],
      });
    } catch (e) {}
  }

  Future<void> _sendDocument() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;
    try {
      final file = File(result.files.single.path!);
      final response = await ApiService.uploadMedia(file, 'file');
      SocketService.sendMessage({
        'sender_id': _myUserId,
        'receiver_id': widget.userId,
        'content': '📄 ${result.files.single.name}',
        'message_type': 'file',
        'media_url': response.data['url'],
      });
    } catch (e) {}
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAttachOption(Icons.image, 'Gallery', Colors.purple, () {
              Navigator.pop(context);
              _sendImage();
            }),
            _buildAttachOption(Icons.camera_alt, 'Camera', Colors.red, () async {
              Navigator.pop(context);
              final picker = ImagePicker();
              final picked = await picker.pickImage(
                  source: ImageSource.camera, imageQuality: 70);
              if (picked != null) {
                final response = await ApiService.uploadMedia(File(picked.path), 'image');
                SocketService.sendMessage({
                  'sender_id': _myUserId,
                  'receiver_id': widget.userId,
                  'content': '📷 Photo',
                  'message_type': 'image',
                  'media_url': response.data['url'],
                });
              }
            }),
            _buildAttachOption(Icons.insert_drive_file, 'Document', Colors.blue, () {
              Navigator.pop(context);
              _sendDocument();
            }),
            _buildAttachOption(Icons.gif, 'GIF', Colors.orange, () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => GifPicker(
                  onGifSelected: (url) {
                    SocketService.sendMessage({
                      'sender_id': _myUserId,
                      'receiver_id': widget.userId,
                      'content': url,
                      'message_type': 'image',
                      'media_url': url,
                    });
                  },
                ),
              );
            }),
            _buildAttachOption(Icons.wallpaper, 'Wallpaper', Colors.teal, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => ChatWallpaperScreen(chatId: widget.userId)));
            }),
            _buildAttachOption(Icons.contacts, 'Contact', Colors.indigo, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => ContactShareScreen(receiverId: widget.userId)));
            }),
            _buildAttachOption(Icons.location_on, 'Location', Colors.green, () {
              Navigator.pop(context);
              _sendLocation();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _sendLocation() async {
    try {
      await ApiService.shareLocation(widget.userId, null, 28.6139, 77.2090, 'New Delhi, India');
    } catch (e) {}
  }

  void _handleReaction(MessageModel message, String emoji) async {
    try {
      await ApiService.addReaction(message.id, emoji);
    } catch (e) {}
  }

  void _handleStar(MessageModel message) async {
    try {
      await ApiService.starMessage(message.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message starred! ⭐')),
        );
      }
    } catch (e) {}
  }

  void _handleDelete(MessageModel message) {
    SocketService.deleteMessage(message.id, widget.userId);
  }

  void _handleForward(MessageModel message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Forward karo'),
        content: const Text('Forward feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _wallpaperColor,
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
                      style: const TextStyle(
                          color: Color(0xFF0084FF), fontWeight: FontWeight.bold))
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
        actions: [
          IconButton(icon: const Icon(Icons.call), onPressed: () {}),
          IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
        ],
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
                          MessageBubble(
                            message: message,
                            isMe: isMe,
                            onReply: (msg) => setState(() => _replyingTo = msg),
                            onForward: _handleForward,
                            onReact: _handleReaction,
                            onDelete: _handleDelete,
                            onStar: _handleStar,
                          ),
                        ],
                      );
                    },
                  ),
          ),
          if (_replyingTo != null) _buildReplyPreview(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildDateDivider(String createdAt) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(_formatDate(createdAt),
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.reply, color: Color(0xFF0084FF)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reply',
                    style: TextStyle(
                        color: Color(0xFF0084FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                Text(
                  _replyingTo!.content ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _replyingTo = null),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.grey),
            onPressed: _showAttachmentOptions,
          ),
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
          _showVoice
              ? VoiceRecorder(onRecorded: _sendVoice)
              : CircleAvatar(
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
// GIF send method - add this to _ChatScreenState
