import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class AuthHelper {
  static const String _secretKey = 'your_super_secret_jwt_key_here';

  // ១. Hash Password ដោយប្រើ SHA-256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // ២. បង្កើត JWT Token (មានអាយុ ៧ ថ្ងៃ)
  static String generateToken(String userId, String role) {
    final jwt = JWT({
      'id': userId,
      'role': role,
    });
    return jwt.sign(SecretKey(_secretKey), expiresIn: const Duration(days: 7));
  }

  // ៣. Verify JWT Token
  static JWT? verifyToken(String token) {
    try {
      return JWT.verify(token, SecretKey(_secretKey));
    } catch (e) {
      return null;
    }
  }
}