class MessageModel {
  final String id;
  final String senderId;
  final String? receiverId;
  final String? groupId;
  final String messageType;
  final String? content;
  final String? mediaUrl;
  final bool isDeleted;
  final bool isRead;
  final String createdAt;
  final String? senderName;
  final String? senderAvatar;

  MessageModel({
    required this.id,
    required this.senderId,
    this.receiverId,
    this.groupId,
    required this.messageType,
    this.content,
    this.mediaUrl,
    required this.isDeleted,
    required this.isRead,
    required this.createdAt,
    this.senderName,
    this.senderAvatar,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      groupId: json['group_id'],
      messageType: json['message_type'] ?? 'text',
      content: json['content'],
      mediaUrl: json['media_url'],
      isDeleted: json['is_deleted'] ?? false,
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'],
      senderName: json['sender_name'],
      senderAvatar: json['sender_avatar'],
    );
  }
}
