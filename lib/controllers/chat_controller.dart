import 'package:connect_hub/models/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'call_controller.dart'; 

class ChatController extends GetxController {
  final SocketService _socketService = Get.find();
  final ApiService _api = Get.find();
  final box = GetStorage();
  String get myUserId => _callController.myUserId; // to make avatar work correctly
  // find the CallController to get roomId and myUserId
  final CallController _callController = Get.find();

  // State
  final chatMessages = <dynamic>[].obs;
  final textController = TextEditingController();
  final isChatOpen = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchChatHistory();
    setupSocketListeners();
  }

  @override
  void onClose() {
    textController.dispose();
    // Remove specific listener to avoid duplicates if re-initialized
    _socketService.socket.off('receive-chat-message');
    super.onClose();
  }

  void fetchChatHistory() async {
    try {
      String roomId = _callController.roomId;
      final res = await _api.getChatHistory(roomId);
      if (res.statusCode == 200) {
        List<dynamic> rawList = res.body;
        chatMessages.value = rawList
            .map((e) => ChatMessage.fromJson(e))
            .toList();
      }
    } catch (e) {
      print("Error loading chat: $e");
    }
  }

  void sendMessage() {
    String text = textController.text.trim();
    if (text.isEmpty) return;

    // Send to Backend
    _socketService.socket.emit('send-chat-message', {
      'roomId': _callController.roomId,
      'senderId': _callController.myUserId,
      'senderName': box.read('username') ?? "Guest",
      'message': text,
    });

    textController.clear();
  }

  void setupSocketListeners() {
    _socketService.socket.on('receive-chat-message', (msg) {
       print("📩 New Message: $msg");
       chatMessages.add(ChatMessage.fromJson(msg));
    });
  }
}