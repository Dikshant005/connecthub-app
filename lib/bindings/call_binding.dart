import 'package:connect_hub/controllers/chat_controller.dart';
import 'package:connect_hub/controllers/screen_share_controller.dart';
import 'package:get/get.dart';
import '../controllers/call_controller.dart';

class CallBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(CallController());
    Get.put(ChatController());
    Get.put(ScreenShareController());
  }
}