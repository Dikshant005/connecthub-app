import 'package:connect_hub/widgets/custom_filed_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView( 
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              
              // logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.video_chat, size: 60, color: Colors.deepPurple),
              ),
              const SizedBox(height: 20),
              const Text(
                "Welcome Back",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const Text(
                "Login to Connect Hub",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // form

              //email
              CustomTextField(
                controller: controller.emailController,
                hintText: "Email Address",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              // password
              CustomTextField(
                controller: controller.passwordController,
                hintText: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 30),

              // login button
              Obx(() => SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : () => controller.login(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "LOG IN",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                ),
              )),

              const SizedBox(height: 20),

              // footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?", style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: () => Get.toNamed(Routes.SIGNUP),
                    child: const Text("Sign Up", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}