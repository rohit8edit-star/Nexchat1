import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  static final Dio _dio = Dio(BaseOptions(baseUrl: BASE_URL));

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', user['id']);
    await prefs.setString('userName', user['name']);
    await prefs.setString('userPhone', user['phone']);
    if (user['avatar'] != null) {
      await prefs.setString('userAvatar', user['avatar']);
    }
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Auth
  static Future<Response> register(String name, String phone) async {
    return await _dio.post('/api/auth/register',
        data: {'name': name, 'phone': phone});
  }

  static Future<Response> verifyOTP(String phone, String token) async {
    return await _dio.post('/api/auth/verify-otp',
        data: {'phone': phone, 'token': token});
  }

  static Future<Response> getProfile() async {
    final headers = await getHeaders();
    return await _dio.get('/api/auth/profile',
        options: Options(headers: headers));
  }

  static Future<Response> searchUsers(String query) async {
    final headers = await getHeaders();
    return await _dio.get('/api/auth/search',
        queryParameters: {'query': query},
        options: Options(headers: headers));
  }

  // Chat
  static Future<Response> getChats() async {
    final headers = await getHeaders();
    return await _dio.get('/api/chat', options: Options(headers: headers));
  }

  static Future<Response> getMessages(String userId) async {
    final headers = await getHeaders();
    return await _dio.get('/api/chat/$userId',
        options: Options(headers: headers));
  }

  static Future<Response> sendMessage(String receiverId, String content,
      {String type = 'text'}) async {
    final headers = await getHeaders();
    return await _dio.post('/api/chat/send',
        data: {
          'receiver_id': receiverId,
          'content': content,
          'message_type': type
        },
        options: Options(headers: headers));
  }

  static Future<Response> deleteMessage(String messageId) async {
    final headers = await getHeaders();
    return await _dio.delete('/api/chat/$messageId',
        options: Options(headers: headers));
  }

  static Future<Response> getUnreadCounts(String userId) async {
    return await _dio.get('/api/chat/unread/$userId');
  }

  // Groups
  static Future<Response> getGroups() async {
    final headers = await getHeaders();
    return await _dio.get('/api/group', options: Options(headers: headers));
  }

  static Future<Response> getGroupMessages(String groupId) async {
    final headers = await getHeaders();
    return await _dio.get('/api/group/$groupId/messages',
        options: Options(headers: headers));
  }

  static Future<Response> createGroup(
      String name, String description, List<String> members) async {
    final headers = await getHeaders();
    return await _dio.post('/api/group/create',
        data: {
          'name': name,
          'description': description,
          'members': members
        },
        options: Options(headers: headers));
  }

  static Future<Response> getGroupMembers(String groupId) async {
    final headers = await getHeaders();
    return await _dio.get('/api/group/$groupId/members',
        options: Options(headers: headers));
  }
}
