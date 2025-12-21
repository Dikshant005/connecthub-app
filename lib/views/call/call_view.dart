import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/call_controller.dart';

class CallView extends GetView<CallController> {
  const CallView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Connecting to Room...", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 20),
            // Display Room ID so we can verify arguments worked
            Text("Room ID: ${controller.roomId}", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}