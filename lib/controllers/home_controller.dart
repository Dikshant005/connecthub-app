import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:math';
import '../routes/app_routes.dart';

class HomeController extends GetxController {
  final box = GetStorage();
  var username = "".obs;

  @override
  void onInit() {
    super.onInit();
    username.value = box.read('username') ?? "Guest";
  }

  // 1. START NEW MEETING
  void startNewMeeting() {
    String roomId = _generateRoomId();
    
    // Navigate to Call Screen with arguments
    Get.toNamed(Routes.CALL, arguments: {
      'roomId': roomId, 
      'isHost': true
    });
  }

  // 2. JOIN MEETING
  void openJoinDialog() {
    TextEditingController roomController = TextEditingController();
    
    Get.defaultDialog(
      title: "Join Meeting",
      content: TextField(
        controller: roomController,
        decoration: const InputDecoration(labelText: "Enter Room ID", border: OutlineInputBorder()),
        keyboardType: TextInputType.number,
      ),
      textConfirm: "Join",
      textCancel: "Cancel",
      onConfirm: () {
        if (roomController.text.length < 5) return;
        Get.back();
        
        // Navigate to Call Screen with arguments
        Get.toNamed(Routes.CALL, arguments: {
          'roomId': roomController.text, 
          'isHost': false
        });
      },
    );
  }

  // 3. SHOW PROFILE DIALOG (Logout Logic)
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
            Get.back(); // Close dialog
            _logout();  // Perform logout
          }, 
          child: const Text("Logout", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  void _logout() {
    box.erase();
    Get.offAllNamed(Routes.LOGIN);
  }

  String _generateRoomId() {
    var rng = Random();
    return (100000 + rng.nextInt(900000)).toString();
  }
}