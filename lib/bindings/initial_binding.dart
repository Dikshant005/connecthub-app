import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart'; 

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ApiService(), permanent: true);
    Get.put(SocketService(), permanent: true);
  }
}