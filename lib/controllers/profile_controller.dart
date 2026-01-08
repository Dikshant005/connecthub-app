import 'dart:io';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../routes/app_routes.dart';

class ProfileController extends GetxController {
  final box = GetStorage();
  final ImagePicker _picker = ImagePicker();
  Rxn<File> profileImage = Rxn<File>();

  @override
  void onInit() {
    super.onInit();
    // load saved path if exists
    String? path = box.read('profileImagePath');
    if (path != null) profileImage.value = File(path);
  }

  Future pickImageFromGallery() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      profileImage.value = File(file.path);
      box.write('profileImagePath', file.path);
      // Optionally upload to server via ApiService
      // final api = Get.find<ApiService>();
      // await api.uploadProfileImage(File(file.path));
    }
  }

  Future pickImageFromCamera() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (file != null) {
      profileImage.value = File(file.path);
      box.write('profileImagePath', file.path);
    }
  }

  void logout() {
    box.erase();
    Get.offAllNamed(Routes.LOGIN);
  }
}