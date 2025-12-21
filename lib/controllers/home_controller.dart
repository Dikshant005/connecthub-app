import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';

class HomeController extends GetxController {
  final ApiService _api = Get.find(); 
  final box = GetStorage();
  
  var username = "".obs;

  @override
  void onInit() {
    // load username from storage to display it
    username.value = box.read('username') ?? "User";
    super.onInit();
  }

  void logout() {
    box.erase(); 
    Get.offAllNamed(Routes.LOGIN);
  }

  void joinMeeting() {
    // Logic coming soon...
    Get.snackbar("Coming Soon", "Join Meeting feature");
  }

  void createMeeting() {
    // Logic coming soon...
    Get.snackbar("Coming Soon", "Create Meeting feature");
  }
}