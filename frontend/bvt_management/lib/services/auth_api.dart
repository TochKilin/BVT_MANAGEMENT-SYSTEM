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
      Uri.parse('${VetApi.baseUrl}/api/auth/register'),
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
        throw ApiException('អ៊ីមែលនេះមានគណនីរួចហើយ');
      }
      throw ApiException(message);
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${VetApi.baseUrl}/api/auth/login'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );

    if (response.statusCode == 403) {
      throw ApiException('អ៊ីមែល ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវ');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(response.body, response.statusCode));
    }

    final data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    await _saveSession(data);
    return data;
  }

  /// ទាញព័ត៌មានប្រវត្តិរូបរបស់អ្នកប្រើដែលកំពុង login
  ///
  /// ចំណាំ: endpoint ខាងក្រោមសន្មតថាមាន GET /api/auth/me នៅ backend
  /// (ដូចគ្នានឹងអ្វីដែល login ប្រើ prefix /api/auth/...)។ បើ backend
  /// របស់អ្នកប្រើ path ផ្សេង សូមកែ Uri.parse ខាងក្រោមតែប៉ុណ្ណោះ។
  static Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();
    if (token == null) throw ApiException('សូមចូលប្រព័ន្ធសិន');

    final response = await http.get(
      Uri.parse('${VetApi.baseUrl}/api/auth/me'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(response.body, response.statusCode));
    }

    final decoded = jsonDecode(response.body);
    // ខ្លះ backend រុំក្នុង { user: {...} } ខ្លះទៀតបញ្ជូនផ្ទាល់
    if (decoded is Map && decoded['user'] is Map) {
      return Map<String, dynamic>.from(decoded['user'] as Map);
    }
    return Map<String, dynamic>.from(decoded as Map);
  }

  /// កែសម្រួល ឈ្មោះ/អ៊ីមែល/លេខទូរស័ព្ទ
  ///
  /// ចំណាំ: endpoint ខាងក្រោមសន្មតថាមាន PUT /api/auth/profile។
  /// កែ Uri.parse ខាងក្រោមឲ្យត្រូវនឹង route ជាក់ស្តែងរបស់ backend បើខុសពីនេះ។
  static Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    final token = await getToken();
    if (token == null) throw ApiException('សូមចូលប្រព័ន្ធសិន');

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name.trim();
    if (email != null) body['email'] = email.trim().toLowerCase();
    if (phone != null) body['phone'] = phone.trim();

    final response = await http.put(
      Uri.parse('${VetApi.baseUrl}/api/auth/profile'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _errorMessage(response.body, response.statusCode);
      if (message.toLowerCase().contains('email')) {
        throw ApiException('អ៊ីមែលនេះមានគណនីរួចហើយ');
      }
      throw ApiException(message);
    }

    // ធ្វើបច្ចុប្បន្នភាព cache ក្នុងម៉ាស៊ីនផងដែរ ដើម្បីកុំឲ្យទិន្នន័យចាស់
    final current = await getUser() ?? <String, dynamic>{};
    if (name != null) current['name'] = name.trim();
    if (email != null) current['email'] = email.trim().toLowerCase();
    if (phone != null) current['phone'] = phone.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(current));
  }

  /// ប្តូរពាក្យសម្ងាត់
  ///
  /// ចំណាំ: endpoint ខាងក្រោមសន្មតថាមាន PUT /api/auth/password ដែលទទួល
  /// { currentPassword, newPassword }។ កែតាម backend ជាក់ស្តែងបើផ្សេង។
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await getToken();
    if (token == null) throw ApiException('សូមចូលប្រព័ន្ធសិន');

    final response = await http.put(
      Uri.parse('${VetApi.baseUrl}/api/auth/password'),
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
      throw ApiException('ពាក្យសម្ងាត់បច្ចុប្បន្នមិនត្រឹមត្រូវ');
    }
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