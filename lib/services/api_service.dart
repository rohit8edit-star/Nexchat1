import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../utils/constants.dart';

class ApiService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: BASE_URL,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

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

  static Future<Options> getAuthOptions() async {
    final token = await getToken();
    return Options(headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
  }

  // ===== AUTH =====
  static Future<Response> register(String name, String phone) async {
    return await _dio.post('/api/auth/register',
        data: {'name': name, 'phone': phone});
  }

  static Future<Response> login(String phone) async {
    return await _dio.post('/api/auth/login', data: {'phone': phone});
  }

  static Future<Response> verifyOTP(String phone, String token) async {
    return await _dio.post('/api/auth/verify-otp',
        data: {'phone': phone, 'token': token});
  }

  static Future<Response> getProfile() async {
    return await _dio.get('/api/auth/profile',
        options: await getAuthOptions());
  }

  static Future<Response> updateProfile(
      String name, String about, File? image) async {
    final token = await getToken();
    final formData = FormData.fromMap({
      'name': name,
      'about': about,
      if (image != null)
        'avatar': await MultipartFile.fromFile(image.path,
            filename: image.path.split('/').last),
    });
    return await _dio.put('/api/auth/profile',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  static Future<Response> searchUsers(String query) async {
    return await _dio.get('/api/auth/search',
        queryParameters: {'query': query},
        options: await getAuthOptions());
  }

  // ===== CHAT =====
  static Future<Response> getChats() async {
    return await _dio.get('/api/chat', options: await getAuthOptions());
  }

  static Future<Response> getMessages(String userId) async {
    return await _dio.get('/api/chat/$userId',
        options: await getAuthOptions());
  }

  static Future<Response> deleteMessage(String messageId) async {
    return await _dio.delete('/api/chat/$messageId',
        options: await getAuthOptions());
  }

  static Future<Response> getUnreadCounts(String userId) async {
    return await _dio.get('/api/chat/unread/$userId');
  }

  // ===== GROUPS =====
  static Future<Response> getGroups() async {
    return await _dio.get('/api/group', options: await getAuthOptions());
  }

  static Future<Response> getGroupMessages(String groupId) async {
    return await _dio.get('/api/group/$groupId/messages',
        options: await getAuthOptions());
  }

  static Future<Response> createGroup(
      String name, String description) async {
    return await _dio.post('/api/group/create',
        data: {'name': name, 'description': description},
        options: await getAuthOptions());
  }

  static Future<Response> getGroupMembers(String groupId) async {
    return await _dio.get('/api/group/$groupId/members',
        options: await getAuthOptions());
  }

  // ===== STATUS =====
  static Future<Response> getStatuses() async {
    return await _dio.get('/api/status', options: await getAuthOptions());
  }

  static Future<Response> createStatus(
      String content, String bgColor) async {
    return await _dio.post('/api/status',
        data: {'content': content, 'bg_color': bgColor, 'status_type': 'text'},
        options: await getAuthOptions());
  }

  static Future<Response> viewStatus(String statusId) async {
    return await _dio.post('/api/status/$statusId/view',
        options: await getAuthOptions());
  }

  static Future<Response> deleteStatus(String statusId) async {
    return await _dio.delete('/api/status/$statusId',
        options: await getAuthOptions());
  }

  // ===== CHANNELS =====
  static Future<Response> getChannels() async {
    return await _dio.get('/api/channel', options: await getAuthOptions());
  }

  static Future<Response> getMyChannels() async {
    return await _dio.get('/api/channel/my',
        options: await getAuthOptions());
  }

  static Future<Response> searchChannels(String query) async {
    return await _dio.get('/api/channel/search',
        queryParameters: {'query': query},
        options: await getAuthOptions());
  }

  static Future<Response> createChannel(
      String name, String description) async {
    return await _dio.post('/api/channel/create',
        data: {'name': name, 'description': description},
        options: await getAuthOptions());
  }

  static Future<Response> subscribeChannel(String channelId) async {
    return await _dio.post('/api/channel/$channelId/subscribe',
        options: await getAuthOptions());
  }

  static Future<Response> getChannelPosts(String channelId) async {
    return await _dio.get('/api/channel/$channelId/posts',
        options: await getAuthOptions());
  }

  // ===== CALLS =====
  static Future<Response> getCallLogs() async {
    return await _dio.get('/api/call', options: await getAuthOptions());
  }

  static Future<Response> saveCallLog(
      String receiverId, String callType, String status, int duration) async {
    return await _dio.post('/api/call/save',
        data: {
          'receiver_id': receiverId,
          'call_type': callType,
          'status': status,
          'duration': duration,
        },
        options: await getAuthOptions());
  }

  // ===== BACKUP =====
  static Future<Response> exportBackup() async {
    return await _dio.get('/api/backup/export',
        options: await getAuthOptions());
  }
}

  // ===== AI =====
  static Future<Response> chatWithAi(String message) async {
    return await _dio.post('/api/ai/chat-simple',
        data: {'message': message},
        options: await getAuthOptions());
  }

  static Future<Response> getAiHistory() async {
    return await _dio.get('/api/ai/history',
        options: await getAuthOptions());
  }

  static Future<Response> clearAiHistory() async {
    return await _dio.delete('/api/ai/history',
        options: await getAuthOptions());
  }

  // ===== MEDIA =====
  static Future<Response> uploadMedia(File file, String type) async {
    final token = await getToken();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path,
          filename: file.path.split('/').last),
    });
    return await _dio.post('/api/media/upload',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  // ===== EXTRAS =====
  static Future<Response> addReaction(String messageId, String emoji) async {
    return await _dio.post('/api/extras/reaction/$messageId',
        data: {'emoji': emoji},
        options: await getAuthOptions());
  }

  static Future<Response> starMessage(String messageId) async {
    return await _dio.post('/api/extras/star/$messageId',
        options: await getAuthOptions());
  }

  static Future<Response> getStarredMessages() async {
    return await _dio.get('/api/extras/starred',
        options: await getAuthOptions());
  }

  static Future<Response> shareLocation(String? receiverId, String? groupId,
      double lat, double lng, String address) async {
    return await _dio.post('/api/share/location',
        data: {
          'receiver_id': receiverId,
          'group_id': groupId,
          'lat': lat,
          'lng': lng,
          'address': address,
        },
        options: await getAuthOptions());
  }

  static Future<Response> searchMessages(String query) async {
    return await _dio.get('/api/extras/search',
        queryParameters: {'query': query},
        options: await getAuthOptions());
  }

  // ===== MUTE/ARCHIVE =====
  static Future<Response> muteChat(String chatId, String chatType) async {
    return await _dio.post('/api/extras/mute',
        data: {'chatId': chatId, 'chatType': chatType},
        options: await getAuthOptions());
  }

  static Future<Response> unmuteChat(String chatId) async {
    return await _dio.delete('/api/extras/mute/$chatId',
        options: await getAuthOptions());
  }

  static Future<Response> archiveChat(String chatId, String chatType) async {
    return await _dio.post('/api/extras/archive',
        data: {'chatId': chatId, 'chatType': chatType},
        options: await getAuthOptions());
  }

  static Future<Response> unarchiveChat(String chatId) async {
    return await _dio.delete('/api/extras/archive/$chatId',
        options: await getAuthOptions());
  }

  // ===== POLLS =====
  static Future<Response> createPoll(String question, List<String> options,
      {String? groupId, String? channelId}) async {
    return await _dio.post('/api/extras/poll',
        data: {
          'question': question,
          'options': options,
          'groupId': groupId,
          'channelId': channelId,
        },
        options: await getAuthOptions());
  }

  static Future<Response> votePoll(String pollId, int optionIndex) async {
    return await _dio.post('/api/extras/poll/$pollId/vote',
        data: {'optionIndex': optionIndex},
        options: await getAuthOptions());
  }

  static Future<Response> getPoll(String pollId) async {
    return await _dio.get('/api/extras/poll/$pollId',
        options: await getAuthOptions());
  }

  // ===== LINK PREVIEW =====
  static Future<Response> getLinkPreview(String url) async {
    return await _dio.get('/api/linkpreview',
        queryParameters: {'url': url},
        options: await getAuthOptions());
  }

  // ===== CONTACT SHARE =====
  static Future<Response> shareContact(String? receiverId, String? groupId,
      String contactName, String contactPhone) async {
    return await _dio.post('/api/share/contact',
        data: {
          'receiver_id': receiverId,
          'group_id': groupId,
          'contact_name': contactName,
          'contact_phone': contactPhone,
        },
        options: await getAuthOptions());
  }
