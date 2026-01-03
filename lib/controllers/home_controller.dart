import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../services/api_service.dart';

class HomeController extends GetxController {
  final ApiService _api = Get.find();
  final box = GetStorage();
  
  // FIX 1: No onClose/dispose here. 
  // GetX will garbage collect this controller when HomeController is destroyed.
  final joinCodeController = TextEditingController();

  String get displayName =>
      box.read('userName') ?? box.read('username') ?? "Guest";

  void logout() {
    box.erase();
    Get.offAllNamed('/login');
  }

  // create meeting
  void createMeeting({String? title}) async {
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Colors.indigo)),
      barrierDismissible: false,
    );

    try {
      final meetingTitle = (title ?? '').trim().isEmpty
          ? "New Meeting"
          : title!.trim();

      final response = await _api.createMeeting(meetingTitle);
      Get.back(); // Close loader

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
      if (Get.isDialogOpen ?? false) Get.back(); // Ensure loader closes on error
      Get.snackbar("Error", e.toString());
    }
  }

  // join meeting
  void joinMeeting() async {
    String code = joinCodeController.text.trim();
    if (code.isEmpty) return;

    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Colors.indigo)), 
      barrierDismissible: false
    );

    try {
      final response = await _api.joinMeeting(code);
      Get.back(); // FIX 2: This closes the loader. ONE time is enough.

      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = response.body;
        if (data is String) data = jsonDecode(data);
        
        if (data['message'] == 'Already joined') {
           debugPrint("WARNING: Server says 'Already Joined'.");
        }

        // REMOVED: Get.back(); <--- This was the bug closing the Home screen
        
        Get.toNamed('/call', arguments: {'roomId': code, 'isHost': false});
      
      } else {
        // Handle error safely
        var body = response.body;
        if (body is String) body = jsonDecode(body);
        String error = body['message'] ?? "Unknown Error";
        
        Get.snackbar("Failed", error, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back(); // Safety check
      Get.snackbar("Error", "Connection failed: $e");
    }
  }
}