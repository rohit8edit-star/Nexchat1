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

  // ===== CALL EVENTS =====
  static void callUser(String callerId, String receiverId, String callType, dynamic offer) {
    _socket?.emit('call_user', {
      'caller_id': callerId,
      'receiver_id': receiverId,
      'call_type': callType,
      'offer': offer,
    });
  }

  static void answerCall(String callerId, dynamic answer) {
    _socket?.emit('answer_call', {
      'caller_id': callerId,
      'answer': answer,
    });
  }

  static void rejectCall(String callerId) {
    _socket?.emit('reject_call', {'caller_id': callerId});
  }

  static void endCall(String otherId, String callType, int duration) {
    _socket?.emit('end_call', {
      'other_id': otherId,
      'call_type': callType,
      'duration': duration,
      'status': 'completed',
    });
  }

  static void onIncomingCall(Function(dynamic) callback) {
    _socket?.off('incoming_call');
    _socket?.on('incoming_call', callback);
  }

  static void onCallAnswered(Function(dynamic) callback) {
    _socket?.off('call_answered');
    _socket?.on('call_answered', callback);
  }

  static void onCallRejected(Function(dynamic) callback) {
    _socket?.off('call_rejected');
    _socket?.on('call_rejected', callback);
  }

  static void onCallEnded(Function(dynamic) callback) {
    _socket?.off('call_ended');
    _socket?.on('call_ended', callback);
  }

  static void onCallFailed(Function(dynamic) callback) {
    _socket?.off('call_failed');
    _socket?.on('call_failed', callback);
  }

  static bool isConnected() {
    return _socket?.connected ?? false;
  }

  static void disconnect() {
    _socket?.disconnect();
  }
}
