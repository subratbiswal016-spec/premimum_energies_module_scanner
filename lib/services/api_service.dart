import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_record.dart';
import '../theme_manager.dart';
import 'db_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> login(String baseUrl, String username, String password) async {
    final cleanUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final url = Uri.parse('$cleanUrl/api/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'token': data['token'],
          'user': data['user'],
        };
      } else {
        String errorMsg = 'Login failed';
        try {
          errorMsg = jsonDecode(response.body)['message'] ?? errorMsg;
        } catch (_) {}
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to the backend server ($e). Please check the URL and ensure the server is running.',
      };
    }
  }

  Future<bool> logout(ThemeManager themeManager) async {
    if (themeManager.token.isEmpty) return false;
    final cleanUrl = themeManager.baseUrl.endsWith('/')
        ? themeManager.baseUrl.substring(0, themeManager.baseUrl.length - 1)
        : themeManager.baseUrl;
    final url = Uri.parse('$cleanUrl/api/auth/logout');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(themeManager.token),
      ).timeout(const Duration(seconds: 30));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Logout API error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> uploadScan(ScanRecord record, {ThemeManager? themeManager}) async {
    String token = themeManager?.token ?? '';
    String baseUrl = themeManager?.baseUrl ?? '';
    
    if (token.isEmpty || baseUrl.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token') ?? '';
      baseUrl = prefs.getString('baseUrl') ?? 'http://10.0.2.2:3000';
    }

    if (token.isEmpty) {
      return {'success': false, 'message': 'No authentication token found'};
    }
    
    final cleanUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final url = Uri.parse('$cleanUrl/api/scans');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'date': record.date,
          'time': record.time,
          'moduleId': record.moduleId,
          'jobCard': record.jobCard,
          'station': record.station,
          'operatorName': record.operatorName,
          'reason': record.reason,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'backendId': data['_id'],
        };
      } else {
        String errorMsg = 'Failed to upload scan';
        try {
          errorMsg = jsonDecode(response.body)['message'] ?? errorMsg;
        } catch (_) {}
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<bool> deleteScan(String backendId, {ThemeManager? themeManager}) async {
    String token = themeManager?.token ?? '';
    String baseUrl = themeManager?.baseUrl ?? '';
    
    if (token.isEmpty || baseUrl.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token') ?? '';
      baseUrl = prefs.getString('baseUrl') ?? 'http://10.0.2.2:3000';
    }

    if (token.isEmpty) return false;
    
    final cleanUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final url = Uri.parse('$cleanUrl/api/scans/$backendId');
    try {
      final response = await http.delete(
        url,
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<ScanRecord>> fetchScans({ThemeManager? themeManager, String? date, String? search}) async {
    String token = themeManager?.token ?? '';
    String baseUrl = themeManager?.baseUrl ?? '';
    
    if (token.isEmpty || baseUrl.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token') ?? '';
      baseUrl = prefs.getString('baseUrl') ?? 'http://10.0.2.2:3000';
    }

    if (token.isEmpty) return [];
    
    final cleanUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    var uri = '$cleanUrl/api/scans';
    final queryParams = <String, String>{};
    if (date != null) queryParams['date'] = date;
    if (search != null) queryParams['search'] = search;
    
    if (queryParams.isNotEmpty) {
      final queryString = Uri(queryParameters: queryParams).query;
      uri = '$uri?$queryString';
    }

    try {
      final response = await http.get(
        Uri.parse(uri),
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) {
          return ScanRecord(
            backendId: json['_id'],
            date: json['date'] ?? '',
            moduleId: json['moduleId'] ?? '',
            jobCard: json['jobCard'] ?? '',
            station: json['station'] ?? '',
            operatorName: json['operatorName'] ?? '',
            reason: json['reason'] ?? '',
            savedBy: json['savedBy'],
            time: json['time'],
            isSynced: true,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Fetch scans error: $e');
    }
    return [];
  }

  Future<int> syncLocalScans(ThemeManager themeManager) async {
    if (themeManager.token.isEmpty) return 0;

    final unsynced = await DBService().getUnsyncedScans();
    if (unsynced.isEmpty) return 0;

    int syncCount = 0;
    for (var record in unsynced) {
      final result = await uploadScan(record, themeManager: themeManager);
      if (result['success'] == true) {
        await DBService().markAsSynced(record.id!, result['backendId']);
        syncCount++;
      }
    }
    return syncCount;
  }

  // Fetch all users (Admin only)
  Future<List<Map<String, dynamic>>> fetchUsers(ThemeManager themeManager, {String? createdBy}) async {
    if (themeManager.token.isEmpty) return [];
    final cleanUrl = themeManager.baseUrl.endsWith('/')
        ? themeManager.baseUrl.substring(0, themeManager.baseUrl.length - 1)
        : themeManager.baseUrl;
    var uri = '$cleanUrl/api/users';
    if (createdBy != null && createdBy.isNotEmpty) {
      uri = '$uri?createdBy=$createdBy';
    }
    final url = Uri.parse(uri);
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(themeManager.token),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint('Fetch users error: $e');
    }
    return [];
  }

  // Register a new user (Admin only)
  Future<Map<String, dynamic>> registerUser(
    ThemeManager themeManager,
    String username,
    String password,
    String role,
  ) async {
    if (themeManager.token.isEmpty) {
      return {'success': false, 'message': 'No authentication token found'};
    }
    final cleanUrl = themeManager.baseUrl.endsWith('/')
        ? themeManager.baseUrl.substring(0, themeManager.baseUrl.length - 1)
        : themeManager.baseUrl;
    final url = Uri.parse('$cleanUrl/api/auth/register');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(themeManager.token),
        body: jsonEncode({
          'username': username,
          'password': password,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'user': data['user'],
        };
      } else {
        String errorMsg = 'Registration failed';
        try {
          errorMsg = jsonDecode(response.body)['message'] ?? errorMsg;
        } catch (_) {}
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Delete a user (Admin only)
  Future<bool> deleteUser(ThemeManager themeManager, String userId) async {
    if (themeManager.token.isEmpty) return false;
    final cleanUrl = themeManager.baseUrl.endsWith('/')
        ? themeManager.baseUrl.substring(0, themeManager.baseUrl.length - 1)
        : themeManager.baseUrl;
    final url = Uri.parse('$cleanUrl/api/users/$userId');
    try {
      final response = await http.delete(
        url,
        headers: _getHeaders(themeManager.token),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Check if a module ID exists in the backend MongoDB database
  Future<bool> checkExistsOnline(String moduleId, {ThemeManager? themeManager}) async {
    String token = themeManager?.token ?? '';
    String baseUrl = themeManager?.baseUrl ?? '';
    
    if (token.isEmpty || baseUrl.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token') ?? '';
      baseUrl = prefs.getString('baseUrl') ?? 'http://10.0.2.2:3000';
    }

    if (token.isEmpty) return false;
    
    final cleanUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final url = Uri.parse('$cleanUrl/api/scans/exists/$moduleId');
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] == true;
      }
    } catch (e) {
      debugPrint('Online check exists error: $e');
    }
    return false;
  }
}
