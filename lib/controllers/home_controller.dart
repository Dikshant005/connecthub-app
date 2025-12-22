import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../services/api_service.dart';

class HomeController extends GetxController {
  final ApiService _api = Get.find();
  final box = GetStorage();
  
  final joinCodeController = TextEditingController();

  String get displayName =>
      box.read('userName') ?? box.read('username') ?? "Guest";

  @override
  void onClose() {
    joinCodeController.dispose();
    super.onClose();
  }

  void logout() {
    box.erase();
    Get.offAllNamed('/login');
  }

  // create meeting
  void createMeeting() async {
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Colors.indigo)),
      barrierDismissible: false,
    );

    try {
      final response =
          await _api.createMeeting("Instant Meeting by $displayName");
      Get.back(); // close loader

      if (response.statusCode == 201) {
        var data = response.body;
        if (data is String) data = jsonDecode(data);

        String roomId = data['roomId'];
        Get.toNamed('/call', arguments: {
          'roomId': roomId,
          'isHost': true,
        });
      } else {
        Get.snackbar("Failed", "Could not create meeting");
      }
    } catch (e) {
      Get.back();
      Get.snackbar("Error", e.toString());
    }
  }

  // join meeting
  void joinMeeting() async {
    String code = joinCodeController.text.trim();
    if (code.isEmpty) return;

    Get.dialog(const Center(child: CircularProgressIndicator(color: Colors.indigo)), barrierDismissible: false);

    try {
      // DEBUGGING IDENTITY
      String myToken = box.read('token') ?? "NO TOKEN";
      String myId = box.read('userId') ?? "NO ID";
      print("🕵️ JOIN ATTEMPT:");
      print("🕵️ User ID in Storage: $myId");
      print("🕵️ Token in Storage: ${myToken.substring(0, 10)}..."); // Print first 10 chars

      print("🚀 CALLING API: POST /meetings/$code/join");
      
      final response = await _api.joinMeeting(code);
      Get.back(); 

      print("📥 STATUS: ${response.statusCode}");
      print("📥 BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check if server ignored us
        var data = response.body;
        if (data is String) data = jsonDecode(data);
        
        // If message is "Already joined" but we are a NEW user, the Token is wrong!
        if (data['message'] == 'Already joined') {
           print("🚨 CRITICAL WARNING: Server says 'Already Joined'.");
           print("🚨 This means the Server thinks you are the HOST.");
        }

        Get.back(); 
        Get.toNamed('/call', arguments: {'roomId': code, 'isHost': false});
      
      } else {
        String error = response.body['message'] ?? "Unknown Error";
        Get.snackbar("Failed", error, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.back();
      print("❌ ERROR: $e");
      Get.snackbar("Error", "Connection failed");
    }
  }
}
