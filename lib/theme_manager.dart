import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _userName = '';
  String _baseUrl = 'https://premier-sccanner-backend.onrender.com';
  String _token = '';
  String _userRole = '';

  ThemeMode get themeMode => _themeMode;
  String get userName => _userName;
  String get baseUrl => _baseUrl;
  String get token => _token;
  String get userRole => _userRole;
  bool get isAuthenticated => _token.isNotEmpty;

  ThemeManager() {
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _userName = prefs.getString('userName') ?? '';
    _baseUrl = prefs.getString('baseUrl') ?? 'https://premier-sccanner-backend.onrender.com';
    _token = prefs.getString('token') ?? '';
    _userRole = prefs.getString('userRole') ?? '';
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

  Future<void> saveAuthData({
    required String userName,
    required String token,
    required String role,
    required String baseUrl,
  }) async {
    _userName = userName;
    _token = token;
    _userRole = role;
    _baseUrl = baseUrl;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', userName);
    await prefs.setString('token', token);
    await prefs.setString('userRole', role);
    await prefs.setString('baseUrl', baseUrl);
  }

  Future<void> saveBaseUrl(String url) async {
    _baseUrl = url;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseUrl', url);
  }

  Future<void> logout() async {
    _userName = '';
    _token = '';
    _userRole = '';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    await prefs.remove('token');
    await prefs.remove('userRole');
  }
}
