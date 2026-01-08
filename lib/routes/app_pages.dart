import 'package:connect_hub/bindings/call_binding.dart';
import 'package:connect_hub/bindings/profile_binding.dart';
import 'package:connect_hub/middleware/auth_middleware.dart';
import 'package:connect_hub/views/auth/reset_password_view.dart';
import 'package:connect_hub/views/call/call_view.dart';
import 'package:connect_hub/views/profile_view.dart';
import 'package:get/get.dart';
import 'app_routes.dart';
import '../bindings/auth_binding.dart';
import '../bindings/home_binding.dart';
import '../views/auth/login_view.dart';
import '../views/auth/signup_view.dart';
import '../views/home/home_view.dart'; 
import '../views/auth/forgot_password_view.dart';

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
      page: () =>  HomeView(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()], 
    ),
    GetPage(
  name: Routes.CALL, 
  page: () => const CallView(),
  binding: CallBinding(),
    ),
    GetPage(
  name: Routes.PROFILE, 
  page: () => const ProfileView(),
  binding: ProfileBinding(),
    ),
    GetPage(
      name: Routes.FORGOT_PASSWORD,
      page: () => const ForgotPasswordView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.RESET_PASSWORD,
      page: () => const ResetPasswordView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.LOGOUT,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
  ];
}