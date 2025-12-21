import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import 'dart:convert';

class HomeController extends GetxController {
  final ApiService _api = Get.find();
  final box = GetStorage();
  var username = "".obs;

  @override
  void onInit() {
    super.onInit();
    username.value = box.read('username') ?? "Guest";
  }

  // 1. CREATE MEETING (Via API -> DB -> Socket)
  // Inside home_controller.dart
  void startNewMeeting() async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

    try {
      final response = await _api.createMeeting("Instant Meeting by $username");
      
      Get.back(); // Close Loading

      print("--- DEBUG SERVER RESPONSE ---");
      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");
      print("-----------------------------");

      if (response.statusCode == 201) {
        // Success Logic...
        var data = response.body;
        if (data is String) data = jsonDecode(data);
        
        String roomId = data['roomId'];
        Get.toNamed(Routes.CALL, arguments: {'roomId': roomId, 'isHost': true});
      
      } else {
        // ERROR HANDLING
        String errorMsg = "Unknown Error";
        if (response.body != null) {
             // Try to extract 'error' from JSON
             try {
                var data = response.body;
                if (data is String) data = jsonDecode(data);
                if (data is Map && data.containsKey('error')) {
                  errorMsg = data['error'];
                }
             } catch(_) {
                errorMsg = response.bodyString ?? "Invalid Response";
             }
        }
        
        Get.snackbar("Failed", "Server said: $errorMsg", 
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.back();
      print("CRASH: $e");
      Get.snackbar("Connection Error", e.toString());
    }
  }

  // 2. JOIN MEETING (Via API -> DB -> Socket)
  void openJoinDialog() {
    TextEditingController roomController = TextEditingController();
    
    Get.defaultDialog(
      title: "Join Meeting",
      content: TextField(
        controller: roomController,
        decoration: const InputDecoration(
          labelText: "Enter Room ID",
          border: OutlineInputBorder()
        ),
        keyboardType: TextInputType.number,
      ),
      textConfirm: "Join",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      onConfirm: () {
        if (roomController.text.length < 5) return;
        String roomId = roomController.text.trim();
        Get.back(); // Close Dialog
        _attemptJoin(roomId);
      },
    );
  }

  void _attemptJoin(String roomId) async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

    try {
      final response = await _api.joinMeeting(roomId);
      
      Get.back(); // Close Loading

      if (response.statusCode == 200) {
        print("✅ Joined Meeting via DB");
        Get.toNamed(Routes.CALL, arguments: {
          'roomId': roomId, 
          'isHost': false
        });
      } 
      else if (response.statusCode == 404) {
        Get.snackbar("Error", "Meeting not found");
      } 
      else if (response.statusCode == 403) {
        Get.snackbar("Access Denied", "Meeting is full or ended", 
          backgroundColor: Colors.orange, colorText: Colors.white);
      } 
      else {
        Get.snackbar("Error", "Cannot join meeting: ${response.statusCode}");
      }
    } catch (e) {
      Get.back();
      Get.snackbar("Connection Error", "Check your internet");
    }
  }

  // 3. LOGOUT & PROFILE
  void showProfileDialog() {
    Get.defaultDialog(
      title: "Profile",
      content: Column(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.deepPurple,
            child: Icon(Icons.person, size: 35, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(username.value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text("Logged in", style: TextStyle(color: Colors.grey)),
        ],
      ),
      confirm: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () {
            Get.back();
            logout();
          }, 
          child: const Text("Logout", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  void logout() {
    _api.logout();
    box.erase();
    Get.offAllNamed(Routes.LOGIN);
  }
}