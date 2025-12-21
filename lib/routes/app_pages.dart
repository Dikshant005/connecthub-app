import 'package:connect_hub/bindings/call_binding.dart';
import 'package:connect_hub/middleware/auth_middleware.dart';
import 'package:connect_hub/views/call/call_view.dart';
import 'package:get/get.dart';
import 'app_routes.dart';
import '../bindings/auth_binding.dart';
import '../bindings/home_binding.dart';
import '../views/auth/login_view.dart';
import '../views/auth/signup_view.dart';
import '../views/home/home_view.dart'; 

class AppPages {
  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.SIGNUP,
      page: () => const SignupView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()], 
    ),
    GetPage(
  name: Routes.CALL, // Define '/call' in app_routes.dart
  page: () => const CallView(),
  binding: CallBinding(),
),
  ];
}