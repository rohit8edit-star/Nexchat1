import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import 'audio_player_widget.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final Function(MessageModel)? onReply;
  final Function(MessageModel)? onForward;
  final Function(MessageModel, String)? onReact;
  final Function(MessageModel)? onDelete;
  final Function(MessageModel)? onStar;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onReply,
    this.onForward,
    this.onReact,
    this.onDelete,
    this.onStar,
  });

  String _formatTime(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return '';
    }
  }

  void _showOptions(BuildContext context) {
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
            // Emoji reactions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['❤️', '😂', '😮', '😢', '👍', '👎'].map((emoji) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onReact?.call(message, emoji);
                  },
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                );
              }).toList(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.reply, color: Color(0xFF0084FF)),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                onReply?.call(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward, color: Color(0xFF0084FF)),
              title: const Text('Forward'),
              onTap: () {
                Navigator.pop(context);
                onForward?.call(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Color(0xFF0084FF)),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.content ?? ''));
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_border, color: Colors.amber),
              title: const Text('Star'),
              onTap: () {
                Navigator.pop(context);
                onStar?.call(message);
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call(message);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.forwardedFrom != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.forward,
                        size: 14,
                        color: isMe ? Colors.white70 : Colors.grey),
                    const SizedBox(width: 4),
                    Text('Forwarded',
                        style: TextStyle(
                            fontSize: 11,
                            color: isMe ? Colors.white70 : Colors.grey,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            Container(
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
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.replyTo != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: isMe
                                ? Colors.white
                                : const Color(0xFF0084FF),
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text('↩ Reply',
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  isMe ? Colors.white70 : Colors.grey)),
                    ),
                  _buildContent(context),
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
                          color: message.isRead
                              ? Colors.white
                              : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (message.reactions != null && message.reactions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4),
                    ],
                  ),
                  child: Text(
                    message.reactions!.keys.join(' '),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (message.isDeleted) {
      return const Text(
        '🚫 Message delete ho gaya',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    switch (message.messageType) {
      case 'image':
        return _buildImageMessage(context);
      case 'audio':
        return AudioPlayerWidget(
          url: message.mediaUrl ?? '',
          isMe: isMe,
        );
      case 'video':
        return _buildVideoMessage(context);
      case 'location':
        return _buildLocationMessage();
      case 'contact':
        return _buildContactMessage();
      case 'file':
        return _buildFileMessage();
      default:
        return Text(
          message.content ?? '',
          style: TextStyle(
            fontSize: 15,
            color: isMe ? Colors.white : Colors.black87,
          ),
        );
    }
  }

  Widget _buildImageMessage(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => Dialog(
          child: Image.network(
            'https://api.webzet.store${message.mediaUrl}',
            fit: BoxFit.contain,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          'https://api.webzet.store${message.mediaUrl}',
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox(
              width: 200,
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF0084FF)),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => const SizedBox(
            width: 200,
            height: 200,
            child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoMessage(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 200,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.play_circle_fill,
              color: Colors.white, size: 48),
        ),
      ),
    );
  }

  Widget _buildLocationMessage() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on,
            color: isMe ? Colors.white : Colors.red),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            message.content ?? 'Location',
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactMessage() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person,
            color: isMe ? Colors.white : const Color(0xFF0084FF)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            message.content ?? 'Contact',
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileMessage() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.insert_drive_file,
            color: isMe ? Colors.white : const Color(0xFF0084FF)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            message.content ?? 'File',
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
