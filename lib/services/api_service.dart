import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ApiService extends GetConnect {
  static const String _baseUrl =
      'https://connecthub.dikshant-ahalawat.live';

  final GetStorage _box = GetStorage();

  @override
  void onInit() {
    httpClient.baseUrl = _baseUrl;
    httpClient.timeout = const Duration(seconds: 20);

    httpClient.addRequestModifier<dynamic>((request) {
      final String? token = _box.read<String>('token');

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.headers['Content-Type'] = 'application/json';
      return request;
    });

    super.onInit();
  }


  Future<Response> login(String email, String password) {
    return post(
      '/auth/login',
      {
        'email': email,
        'password': password,
      },
    );
  }

  Future<Response> signup(
    String username,
    String email,
    String password,
  ) {
    return post(
      '/auth/signup',
      {
        'username': username,
        'email': email,
        'password': password,
      },
    );
  }

  Future<Response> logout() {
    return post('/auth/logout', {});
  }

  Future<Response> forgotPassword(String email) {
    return post(
      '/auth/forgot-password', 
      {'email': email},
    );
  }

  Future<Response> resetPassword({
    String? token,
    required String newPassword,
  }) {
    final Map<String, dynamic> body = {
      'newPassword': newPassword,
    };

    if (token != null && token.isNotEmpty) {
      body['token'] = token;
    }

    return post('/auth/reset-password', body);
  }

  Future<Response> createMeeting(String title) {
    return post(
      '/meetings',
      {
        'title': title,
        'scheduledAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<Response> joinMeeting(String roomId) {
    return post('/meetings/$roomId/join', {});
  }

  Future<Response> leaveMeeting(String roomId) {
    return post('/meetings/$roomId/leave', {});
  }

  Future<Response> endMeeting(String roomId) {
    return post('/meetings/$roomId/end', {});
  }

  Future<Response> getParticipants(String roomId) {
    return get('/meetings/$roomId/participants');
  }


  Future<Response> getChatHistory(String roomId) {
    return get('/chat/$roomId');
  }
}
