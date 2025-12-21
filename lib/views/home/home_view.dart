import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connect Hub"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => controller.logout(),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() => Text(
              "Welcome, ${controller.username.value}!",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            )),
            const SizedBox(height: 30),
            
            // JOIN BUTTON
            ElevatedButton.icon(
              onPressed: controller.joinMeeting,
              icon: const Icon(Icons.video_call),
              label: const Text("Join Meeting"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // CREATE BUTTON
            OutlinedButton.icon(
              onPressed: controller.createMeeting,
              icon: const Icon(Icons.add),
              label: const Text("Create Meeting"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}