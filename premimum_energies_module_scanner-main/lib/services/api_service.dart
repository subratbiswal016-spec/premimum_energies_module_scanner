import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_record.dart';

class ApiService {
  // Change this to your server's IP address
  // For Android emulator: http://10.0.2.2:3000/api
  // For physical device: http://<your-pc-ip>:3000/api
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== AUTH ====================

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['token']);
      await prefs.setString('username', data['user']['username']);
      await prefs.setString('role', data['user']['role']);
      await prefs.setString('userId', data['user']['id']);
    }
    return {'statusCode': response.statusCode, 'data': data};
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('username');
    await prefs.remove('role');
    await prefs.remove('userId');
  }

  static Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? '';
  }

  static Future<String> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role') ?? 'user';
  }

  static Future<bool> isAdmin() async {
    final role = await getRole();
    return role == 'admin';
  }

  // ==================== USERS (Admin only) ====================

  static Future<Map<String, dynamic>> registerUser(String username, String password, {String role = 'user'}) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: headers,
      body: jsonEncode({'username': username, 'password': password, 'role': role}),
    );
    return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<List<Map<String, dynamic>>> getUsers() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/users'), headers: headers);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/users/$userId'), headers: headers);
    return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
  }

  // ==================== SCANS ====================

  static Future<List<ScanRecord>> getScans({String? date, String? search, String? startDate, String? endDate}) async {
    final headers = await _getHeaders();
    String url = '$baseUrl/scans';
    List<String> params = [];

    if (date != null) params.add('date=$date');
    if (search != null) params.add('search=$search');
    if (startDate != null) params.add('startDate=$startDate');
    if (endDate != null) params.add('endDate=$endDate');

    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => ScanRecord.fromJson(json)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> createScan(ScanRecord record) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/scans'),
      headers: headers,
      body: jsonEncode(record.toJson()),
    );
    return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> deleteScan(String scanId) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/scans/$scanId'), headers: headers);
    return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<bool> isDuplicate(String moduleId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/scans/duplicates/$moduleId'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['isDuplicate'] ?? false;
    }
    return false;
  }

  static Future<bool> checkExists(String moduleId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/scans/exists/$moduleId'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['exists'] ?? false;
    }
    return false;
  }

  static Future<List<String>> getDatesWithData() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/scans/dates'), headers: headers);
    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    }
    return [];
  }
}
