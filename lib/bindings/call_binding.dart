import 'package:connect_hub/controllers/chat_controller.dart';
import 'package:get/get.dart';
import '../controllers/call_controller.dart';

class CallBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CallController>(() => CallController());
    Get.put(ChatController());
  }
}