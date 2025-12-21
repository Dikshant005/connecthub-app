import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ApiService extends GetConnect {
  final String mainUrl = "https://connecthub.dikshant-ahalawat.live"; 
  
  final box = GetStorage();

  @override
  void onInit() {
    httpClient.baseUrl = mainUrl; 
    
    allowAutoSignedCert = true; 
    httpClient.timeout = const Duration(seconds: 20);

    // add token to request headers 
    httpClient.addRequestModifier<dynamic>((request) {
      String? token = box.read('token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      return request;
    });

    super.onInit();
  }

  // auth endpoints

  Future<Response> login(String email, String password) {
    return post('/auth/login', { "email": email, "password": password });
  }

  Future<Response> signup(String username, String email, String password) {
    return post('/auth/signup', { "username": username, "email": email, "password": password });
  }
  
  Future<Response> logout() {
    return post('/auth/logout', {});
  }

  // meeting endpoints

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
  Future<Response> leaveMeeting(String roomId) {
    return post('/meetings/$roomId/leave', {});
  }

  // Host destroys meeting
  Future<Response> endMeeting(String roomId) {
    return post('/meetings/$roomId/end', {});
  }
}