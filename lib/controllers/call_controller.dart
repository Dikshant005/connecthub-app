import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../services/socket_service.dart';

class CallController extends GetxController {
  final SocketService _socketService = Get.find();
  final box = GetStorage();

  late String roomId;
  late bool isHost;
  late String userId;

  @override
  void onInit() {
    super.onInit();
    
    // Get Arguments passed from Home Screen
    var args = Get.arguments;
    roomId = args['roomId'];
    isHost = args['isHost'];
    userId = box.read('userId') ?? "Unknown";

    // connect to room
    _joinRoom();
  }

  void _joinRoom() {
    debugPrint("📞 CallController Initialized. Joining Room: $roomId as User: $userId");
    _socketService.joinRoom(roomId, userId);
  }
}