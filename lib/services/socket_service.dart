import 'package:socket_io_client/socket_io_client.dart' as io;
import '../utils/constants.dart';

class SocketService {
  static io.Socket? _socket;

  static void connect(String userId) {
    _socket = io.io(SOCKET_URL, io.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(999)
        .setReconnectionDelay(1000)
        .build());

    _socket!.onConnect((_) {
      _socket!.emit('user_online', userId);
    });

    _socket!.onReconnect((_) {
      _socket!.emit('user_online', userId);
    });
  }

  static void joinRoom(String roomId) {
    _socket?.emit('join_room', roomId);
  }

  static void sendMessage(Map<String, dynamic> data) {
    _socket?.emit('send_message', data);
  }

  static void onNewMessage(Function(dynamic) callback) {
    _socket?.off('new_message');
    _socket?.on('new_message', callback);
  }

  static void onTyping(Function(dynamic) callback) {
    _socket?.off('typing');
    _socket?.on('typing', callback);
  }

  static void onStopTyping(Function(dynamic) callback) {
    _socket?.off('stop_typing');
    _socket?.on('stop_typing', callback);
  }

  static void onMessageDeleted(Function(dynamic) callback) {
    _socket?.off('message_deleted');
    _socket?.on('message_deleted', callback);
  }

  static void onMessagesRead(Function(dynamic) callback) {
    _socket?.off('messages_read');
    _socket?.on('messages_read', callback);
  }

  static void onUserStatus(Function(dynamic) callback) {
    _socket?.off('user_status');
    _socket?.on('user_status', callback);
  }

  static void emitTyping(String senderId, String receiverId) {
    _socket?.emit('typing', {'sender_id': senderId, 'receiver_id': receiverId});
  }

  static void emitStopTyping(String senderId, String receiverId) {
    _socket?.emit('stop_typing', {'sender_id': senderId, 'receiver_id': receiverId});
  }

  static void emitMessageRead(String senderId, String receiverId) {
    _socket?.emit('message_read', {'sender_id': senderId, 'receiver_id': receiverId});
  }

  static void deleteMessage(String messageId, String receiverId) {
    _socket?.emit('delete_message', {'message_id': messageId, 'receiver_id': receiverId});
  }

  static bool isConnected() {
    return _socket?.connected ?? false;
  }

  static void disconnect() {
    _socket?.disconnect();
  }
}
