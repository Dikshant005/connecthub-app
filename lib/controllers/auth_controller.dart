import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../routes/app_routes.dart';

class AuthController extends GetxController {
  final ApiService _api = Get.find();
  final box = GetStorage();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController(); 

  var isLoading = false.obs;

  //login
  void login() async {
    if (!_validateFields(isSignup: false)) return;

    isLoading.value = true;
    try {
      final response = await _api.login(emailController.text.trim(), passwordController.text.trim());
      final data = _parseBody(response.body);

      if (response.statusCode == 200) {
       
        // success
        box.write('token', data['token']);
        box.write('userId', data['userId']);
        box.write('username', data['username']);
        
        Get.offAllNamed(Routes.HOME);
      } else {
        // error
        _showErrorSnackbar("Login Failed", data);
      }
    } catch (e) {
      _showConnectionError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // signup
  void signup() async {
    if (!_validateFields(isSignup: true)) return;

    isLoading.value = true;
    try {
      final response = await _api.signup(
        nameController.text.trim(),
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      final data = _parseBody(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // success
        Get.snackbar("Success", "Account created! Please login.", 
          backgroundColor: Colors.green, colorText: Colors.white);
        Get.offNamed(Routes.LOGIN);
      } else {
        // error
        _showErrorSnackbar("Signup Failed", data);
      }
    } catch (e) {
      _showConnectionError(e);
    } finally {
      isLoading.value = false;
    }
  }

  //logout
  void logout() async {

    await _api.logout();  
    box.erase();
    Get.offAllNamed(Routes.LOGIN);
  }

  // validates input fields not empty  
  bool _validateFields({required bool isSignup}) {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar("Error", "Please fill in all fields", backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }
    if (isSignup && nameController.text.isEmpty) {
      Get.snackbar("Error", "Username is required", backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }
    return true;
  }

  /// parsing string body to json if needed
  dynamic _parseBody(dynamic body) {
    if (body is String) {
      try {
        return jsonDecode(body);
      } catch (_) {
        return body; 
      }
    }
    return body;
  }

  /// error handling
  void _showErrorSnackbar(String title, dynamic data) {
    String errorMsg = "Unknown Error";
    if (data is Map && data.containsKey('error')) {
      errorMsg = data['error'];
    } else if (data is String) {
      errorMsg = data;
    }
    Get.snackbar(title, errorMsg, backgroundColor: Colors.redAccent, colorText: Colors.white);
  }

  void _showConnectionError(dynamic error) {
    Get.snackbar("Connection Error", "Could not reach the server.", backgroundColor: Colors.redAccent, colorText: Colors.white);
  }
}