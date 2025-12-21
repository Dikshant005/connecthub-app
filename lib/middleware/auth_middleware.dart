import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final box = GetStorage();
    final token = box.read('token');

    // no token --> login
    if (token == null) {
      return const RouteSettings(name: Routes.LOGIN);
    }

    //if token exists--> proceed to requested route
    return null;
  }
}