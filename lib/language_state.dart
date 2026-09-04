import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageNotifier extends ChangeNotifier {
  bool _isEnglish = false; // false = Tiếng Việt, true = English

  bool get isEnglish => _isEnglish;

  LanguageNotifier() {
    _load();
  }

  // Hàm private load từ prefs
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnglish = prefs.getBool('is_english') ?? false;
    notifyListeners();
  }

  // Hàm toggle - lưu luôn vào prefs
  Future<void> toggle() async {
    _isEnglish = !_isEnglish;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_english', _isEnglish);
    notifyListeners();
  }
}