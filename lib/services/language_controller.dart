import 'package:get/get.dart';

class LanguageController extends GetxController {
  bool isEnglish = true;

  void setLanguage(bool value) {
    isEnglish = value;
  }
}
