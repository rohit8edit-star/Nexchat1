import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/constants.dart';

class SocketService {
  static IO.Socket? _socket;

  static void connect(String userId) {
    _socket = IO.io(SOCKET_URL, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.onConnect((_) {
      print('✅ Socket connected!');
      _socket!.emit('user_online', userId);
    });

    _socket!.onDisconnect((_) {
      print('❌ Socket disconnected!');
    });
  }

  static void joinRoom(String roomId) {
    _socket?.emit('join_room', roomId);
  }

  static void sendMessage(Map<String, dynamic> data) {
    _socket?.emit('send_message', data);
  }

  static void onNewMessage(Function(dynamic) callback) {
    _socket?.on('new_message', callback);
  }

  static void onTyping(Function(dynamic) callback) {
    _socket?.on('typing', callback);
  }

  static void onStopTyping(Function(dynamic) callback) {
    _socket?.on('stop_typing', callback);
  }

  static void onMessageDeleted(Function(dynamic) callback) {
    _socket?.on('message_deleted', callback);
  }

  static void onUserStatus(Function(dynamic) callback) {
    _socket?.on('user_status', callback);
  }

  static void emitTyping(String senderId, String receiverId) {
    _socket?.emit('typing', {'sender_id': senderId, 'receiver_id': receiverId});
  }

  static void emitStopTyping(String senderId, String receiverId) {
    _socket?.emit('stop_typing', {'sender_id': senderId, 'receiver_id': receiverId});
  }

  static void deleteMessage(String messageId, String receiverId) {
    _socket?.emit('delete_message', {'message_id': messageId, 'receiver_id': receiverId});
  }

  static void disconnect() {
    _socket?.disconnect();
  }
}
