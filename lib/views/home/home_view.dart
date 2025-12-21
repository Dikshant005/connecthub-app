import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Connect Hub", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          // PROFILE AVATAR
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: controller.showProfileDialog,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.person, color: Colors.deepPurple),
              ),
            ),
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. CREATE MEETING BUTTON (Big & Prominent)
              InkWell(
                onTap: controller.startNewMeeting,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                    ]
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_call, size: 50, color: Colors.white),
                      SizedBox(height: 10),
                      Text("Create Instant Meeting", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),

              // 2. JOIN MEETING BUTTON (Outlined)
              InkWell(
                onTap: controller.openJoinDialog,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.deepPurple, width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.keyboard_alt_outlined, size: 50, color: Colors.deepPurple),
                      SizedBox(height: 10),
                      Text("Join with Code", style: TextStyle(color: Colors.deepPurple, fontSize: 18, fontWeight: FontWeight.bold))
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}