import 'package:connect_hub/bindings/initial_binding.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

void main() async {
  await GetStorage.init(); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    
    //initial binding
    // if token exists, go to home, else login
    final String initialRoute = box.hasData('token') ? Routes.HOME : Routes.LOGIN;

    return GetMaterialApp(
    initialBinding: InitialBinding(),
      title: 'Connect Hub',
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute, 
      getPages: AppPages.routes,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
    );
  }
}