import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'vet_api.dart' show VetApi, ApiException;

class AuthApi {
  AuthApi._();

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String role = 'User',
  }) async {
    final response = await http.post(
      Uri.parse('${VetApi.baseUrl}/api/v1/auth/register'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'phone': phone.trim(),
        'role': role,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _errorMessage(response.body, response.statusCode);
      if (message.toLowerCase().contains('email')) {
        throw ApiException('Your email use already');
      }
      throw ApiException(message);
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${VetApi.baseUrl}/api/v1/auth/login'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );

    if (response.statusCode == 403) {
      throw ApiException('Incorrect email or password');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(response.body, response.statusCode));
    }

    final data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    await _saveSession(data);
    return data;
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();
    if (token == null) throw ApiException('please enter to system');

    final response = await http.get(
      Uri.parse('${VetApi.baseUrl}/api/v1/auth/me'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(response.body, response.statusCode));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['user'] is Map) {
      return Map<String, dynamic>.from(decoded['user'] as Map);
    }
    return Map<String, dynamic>.from(decoded as Map);
  }

  static Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    final token = await getToken();
    if (token == null) throw ApiException('PLease enter to system');

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name.trim();
    if (email != null) body['email'] = email.trim().toLowerCase();
    if (phone != null) body['phone'] = phone.trim();

    final response = await http.put(
      Uri.parse('${VetApi.baseUrl}/api/v1/auth/profile'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _errorMessage(response.body, response.statusCode);
      if (message.toLowerCase().contains('email')) {
        throw ApiException('Your email have already');
      }
      throw ApiException(message);
    }

    final current = await getUser() ?? <String, dynamic>{};
    if (name != null) current['name'] = name.trim();
    if (email != null) current['email'] = email.trim().toLowerCase();
    if (phone != null) current['phone'] = phone.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(current));
  }

  static Future<String> updateAvatar(File imageFile) async {
    final token = await getToken();
    if (token == null) throw ApiException('Please login to system');

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('${VetApi.baseUrl}/api/v1/auth/avatar'),
    );
    request.headers['authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('avatar', imageFile.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(response.body, response.statusCode));
    }

    final decoded = jsonDecode(response.body);
    String? avatarUrl;
    if (decoded is Map) {
      final user = decoded['user'];
      avatarUrl = decoded['avatarUrl']?.toString() ??
          decoded['avatar']?.toString() ??
          (user is Map ? user['avatarUrl']?.toString() : null);
    }

    final current = await getUser() ?? <String, dynamic>{};
    if (avatarUrl != null) current['avatarUrl'] = avatarUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(current));

    return avatarUrl ?? '';
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await getToken();
    if (token == null) throw ApiException('please login to system');

    final response = await http.put(
      Uri.parse('${VetApi.baseUrl}/api/v1/auth/password'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 403 || response.statusCode == 401) {
      throw ApiException('your password present is false');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(response.body, response.statusCode));
    }
  }

  /// Password reset used by the mock OTP flow. The server updates the account
  /// found by its registered email address or phone number.
  static Future<void> resetPassword({
    required String contact,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('${VetApi.baseUrl}/api/v1/auth/reset-password'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'contact': contact.trim(),
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(response.body, response.statusCode));
    }
  }

  static Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = data['token']?.toString();
    if (token != null) await prefs.setString(_tokenKey, token);
    if (data['user'] != null) await prefs.setString(_userKey, jsonEncode(data['user']));
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  static Future<bool> isLoggedIn() async => (await getToken()) != null;

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static String _errorMessage(String body, int status) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['error']?.toString() ?? 'Server error ($status)';
    } catch (_) {
      return 'Server error ($status)';
    }
  }
}
