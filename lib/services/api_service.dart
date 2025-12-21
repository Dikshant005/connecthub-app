import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ApiService extends GetConnect {
  // 1. Set Base URL to the ROOT domain (No /auth or /meetings yet)
  final String mainUrl = "https://connecthub.dikshant-ahalawat.live"; 
  
  final box = GetStorage();

  @override
  void onInit() {
    httpClient.baseUrl = mainUrl; // Set root as base
    
    allowAutoSignedCert = true; 
    httpClient.timeout = const Duration(seconds: 20);

    // Add Token to requests
    httpClient.addRequestModifier<dynamic>((request) {
      String? token = box.read('token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      return request;
    });

    super.onInit();
  }

  // --- AUTH ENDPOINTS (Add /auth here) ---

  Future<Response> login(String email, String password) {
    return post('/auth/login', { "email": email, "password": password });
  }

  Future<Response> signup(String username, String email, String password) {
    return post('/auth/signup', { "username": username, "email": email, "password": password });
  }
  
  Future<Response> logout() {
    return post('/auth/logout', {});
  }

  // --- MEETING ENDPOINTS (Add /meetings here) ---

  Future<Response> createMeeting(String title) {
    // Result: https://connecthub.dikshant-ahalawat.live/meetings/
    return post(
      '/meetings/', 
      {
        "title": title,
        "scheduledAt": DateTime.now().toIso8601String(),
      }
    );
  }

  Future<Response> joinMeeting(String roomId) {
    // Result: https://connecthub.dikshant-ahalawat.live/meetings/123456/join
    return post(
      '/meetings/$roomId/join', 
      {} 
    );
  }
}