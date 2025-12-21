import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ApiService extends GetConnect {
  final String url = "https://connecthub.dikshant-ahalawat.live/auth";
  final box = GetStorage();

  @override
  void onInit() {
    httpClient.baseUrl = url;
    
    // add bearer token to headers if exists
    httpClient.addRequestModifier<dynamic>((request) {
      String? token = box.read('token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      return request;
    });
    
    super.onInit();
  }
  Future<Response> login(String email, String password) {
    return post(
      '/login', 
      {
        "email": email, 
        "password": password
      }
    );
  }

  Future<Response> signup(String username, String email, String password) {
    return post(
      '/signup', 
      {
        "username": username, 
        "email": email, 
        "password": password
      }
    );
  }
  Future<Response> logout() {
    return post('/logout', {});
  }
}