import 'package:get/get.dart';
import '../services/api_service.dart';
// import '../services/socket_service.dart'; // We will add this later

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Put ApiService permanently (permanent: true is default for services)
    Get.put(ApiService(), permanent: true);
    
    // 2. We will put SocketService here later when we build it
    // Get.put(SocketService(), permanent: true);
  }
}