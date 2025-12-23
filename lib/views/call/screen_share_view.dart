import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/screen_share_controller.dart';

class ScreenShareView extends GetView<ScreenShareController> {
  const ScreenShareView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated or Static Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.present_to_all_rounded,
              color: Colors.blue,
              size: 50,
            ),
          ),
          const SizedBox(height: 16),
          
          const Text(
            "You are sharing your screen",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            "Notifications and passwords are visible to others.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Stop Button
          ElevatedButton.icon(
            onPressed: controller.stopScreenShare,
            icon: const Icon(Icons.stop_screen_share, size: 18),
            label: const Text("Stop Sharing"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          )
        ],
      ),
    );
  }
}