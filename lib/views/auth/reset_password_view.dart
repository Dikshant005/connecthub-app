import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class ResetPasswordView extends GetView<AuthController> {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final String? token = args != null ? args['token'] as String? : null;

    final TextEditingController newPassCtrl = TextEditingController();
    final TextEditingController confirmPassCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            if (token != null) ...[
              const Text('Reset your password using the link from your email.', style: TextStyle(color: Colors.grey)),
            ] else ...[
              const Text('Reset your password.', style: TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 12),

            TextField(
              controller: newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final newPass = newPassCtrl.text.trim();
                  final confirm = confirmPassCtrl.text.trim();

                  if (newPass.isEmpty || confirm.isEmpty) {
                    Get.snackbar('Error', 'Please fill in all fields', backgroundColor: Colors.redAccent, colorText: Colors.white);
                    return;
                  }
                  if (newPass.length < 6) {
                    Get.snackbar('Error', 'Password must be at least 6 characters', backgroundColor: Colors.redAccent, colorText: Colors.white);
                    return;
                  }
                  if (newPass != confirm) {
                    Get.snackbar('Error', 'Passwords do not match', backgroundColor: Colors.redAccent, colorText: Colors.white);
                    return;
                  }

                  controller.resetPassword(token: token, newPassword: newPass);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                child: const Text('Reset Password', style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
