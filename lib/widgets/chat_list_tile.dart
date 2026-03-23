import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ChatListTile extends StatelessWidget {
  final Map<String, dynamic> chat;
  final bool isGroup;
  final int unreadCount;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  const ChatListTile({
    super.key,
    required this.chat,
    required this.isGroup,
    required this.unreadCount,
    required this.onTap,
    required this.onRefresh,
  });

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
    return Dismissible(
      key: Key(chat['id']),
      background: Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volume_off, color: Colors.white),
            Text('Mute', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: Colors.grey,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.archive, color: Colors.white),
            Text('Archive',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Mute
          await ApiService.muteChat(chat['id'], isGroup ? 'group' : 'user');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${chat['name']} muted!'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  await ApiService.unmuteChat(chat['id']);
                  onRefresh();
                },
              ),
            ),
          );
          onRefresh();
          return false;
        } else {
          // Archive
          await ApiService.archiveChat(
              chat['id'], isGroup ? 'group' : 'user');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${chat['name']} archived!'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  await ApiService.unarchiveChat(chat['id']);
                  onRefresh();
                },
              ),
            ),
          );
          onRefresh();
          return false;
        }
      },
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: isGroup
                  ? const Color(0xFF0066CC)
                  : const Color(0xFF0084FF),
              backgroundImage: chat['avatar'] != null
                  ? NetworkImage(
                      'https://api.webzet.store${chat['avatar']}')
                  : null,
              child: chat['avatar'] == null
                  ? Text(
                      chat['name'][0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    )
                  : null,
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (isGroup)
                        const Icon(Icons.group,
                            size: 14, color: Colors.grey),
                      if (isGroup) const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          chat['name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatTime(chat['created_at'] ??
                      chat['last_message_time']),
                  style: TextStyle(
                    fontSize: 12,
                    color: unreadCount > 0
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
                    chat['content'] ?? chat['last_message'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unreadCount > 0
                          ? Colors.black87
                          : Colors.grey,
                      fontWeight: unreadCount > 0
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0084FF),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            onTap: onTap,
          ),
          const Divider(height: 1, indent: 80),
        ],
      ),
    );
  }
}
