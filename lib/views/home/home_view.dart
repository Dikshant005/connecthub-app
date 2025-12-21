import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:math';

class HomeView extends StatelessWidget {
  HomeView({super.key});

  final box = GetStorage();
  final TextEditingController _joinCodeController = TextEditingController();

  // logout bottom sheet
  void _logout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text("Log Out", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            const SizedBox(height: 10),
            Text("Are you sure you want to log out of ConnectHub?", 
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16)
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                    child: const Text("Cancel", style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      box.erase(); 
                      Get.offAllNamed('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                    child: const Text("Yes, Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // generate random room id
  String _generateRoomId() {
    var r = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz1234567890';
    return List.generate(8, (index) => chars[r.nextInt(chars.length)]).join();
  }

  void _startNewMeeting() {
    String roomId = _generateRoomId();
    Get.toNamed('/call', arguments: {'roomId': roomId, 'isHost': true});
  }

  // join bottom sheet
  void _showJoinDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
          left: 24, right: 24, top: 24
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Join a Meeting", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Enter the code shared by the host.", style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 25),
            TextField(
              controller: _joinCodeController,
              decoration: InputDecoration(
                hintText: "e.g. abc-123",
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.keyboard, color: Colors.indigo),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (_joinCodeController.text.trim().isNotEmpty) {
                    Get.back();
                    Get.toNamed('/call', arguments: {
                      'roomId': _joinCodeController.text.trim(),
                      'isHost': false
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text("Join Now", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // fetch username from storage
    String displayName = box.read('username') ?? "Guest";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("ConnectHub", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          // logout button
          TextButton(
            onPressed: () => _logout(context),
            child: Text("Logout", style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.indigo.shade50,
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : "U",
              style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
            
            // welcome text
            Text("Welcome back,", style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF3F51B5), // Deep Indigo
                  Color(0xFF2196F3), // Bright Blue
                  Color(0xFF00BCD4), // Shiny Cyan
                ],
                stops: [0.0, 0.5, 1.0], // transition points
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                displayName,
                style: const TextStyle(
                  fontSize: 34, 
                  fontWeight: FontWeight.w900, 
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 4),
                      blurRadius: 10,
                    )
                  ]
                ),
              ),
            ),
            const Spacer(),

            // cards
            _buildLargeButton(
              title: "New Meeting",
              subtitle: "Start an instant meeting.",
              icon: Icons.videocam_rounded,
              color: Colors.indigo,
              textColor: Colors.white,
              iconColor: Colors.white,
              onTap: _startNewMeeting,
            ),

            const SizedBox(height: 20),

            _buildLargeButton(
              title: "Join Meeting",
              subtitle: "Enter a code to join.",
              icon: Icons.add_to_queue_rounded,
              color: const Color(0xFFF5F5FF), // Very light indigo
              textColor: Colors.indigo,
              iconColor: Colors.indigo,
              onTap: () => _showJoinDialog(context),
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLargeButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color == Colors.indigo ? Colors.indigo.withValues(alpha: 0.3) : Colors.transparent,
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}