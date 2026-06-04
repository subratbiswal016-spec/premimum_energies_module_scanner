import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  String _userName = '';

  ThemeMode get themeMode => _themeMode;
  String get userName => _userName;

  ThemeManager() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _userName = prefs.getString('userName') ?? '';
    notifyListeners();
  }

  void toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDark', _themeMode == ThemeMode.dark);
  }

  Future<void> saveUserName(String name) async {
    _userName = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('userName', name);
  }
}
