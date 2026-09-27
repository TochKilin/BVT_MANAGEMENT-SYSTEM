import 'dart:convert';
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import '../config/database.dart';
import '../models/user_model.dart';
import '../utils/auth_helper.dart';

class AuthController {
  Future<Response> register(Request request) async {
    try {
      final payload = await request.readAsString();
      if (payload.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Request body cannot be empty'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final body = jsonDecode(payload) as Map<String, dynamic>;
      final collection = await DatabaseService.getCollection('users');

      final existingUser = await collection.findOne({'email': body['email']});
      if (existingUser != null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Email already exists'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final hashedPassword = AuthHelper.hashPassword(body['password']);

      final user = UserModel(
        name: body['name'],
        email: body['email'],
        password: hashedPassword,
        phone: body['phone'],
        role: RoleModel(name: body['role'] ?? 'User', description: ''),
      );

      await collection.insertOne(user.toMap());

      return Response.ok(
        jsonEncode({'message': 'User registered successfully'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, stackTrace) {
      print('Register Error: $e');
      print(stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal Server Error: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> login(Request request) async {
    try {
      final payload = await request.readAsString();
      if (payload.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Request body cannot be empty'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final body = jsonDecode(payload) as Map<String, dynamic>;
      final collection = await DatabaseService.getCollection('users');

      final hashedPassword = AuthHelper.hashPassword(body['password']);
      final user = await collection.findOne({
        'email': body['email'],
        'password': hashedPassword,
      });

      if (user == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Invalid email or password'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final userModel = UserModel.fromMap(user);
      final token = AuthHelper.generateToken(
        userModel.id!.toHexString(),
        userModel.role.name,
      );

      return Response.ok(
        jsonEncode({
          'message': 'Login successful',
          'token': token,
          'user': {
            'id': userModel.id!.toHexString(),
            'name': userModel.name,
            'email': userModel.email,
            'phone': userModel.phone,
            'role': userModel.role.name,
            'avatarUrl': userModel.avatarUrl,
          }
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, stackTrace) {
      print('Login Error: $e');
      print(stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal Server Error: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> me(Request request) async {
    try {
      final userId = _requireUserId(request);
      if (userId == null) return _unauthorized();

      final collection = await DatabaseService.getCollection('users');
      final user = await collection.findOne({'_id': ObjectId.fromHexString(userId)});
      if (user == null) {
        return Response.notFound(
          jsonEncode({'error': 'User not found'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final userModel = UserModel.fromMap(user);
      return Response.ok(
        jsonEncode({
          'user': {
            'id': userModel.id!.toHexString(),
            'name': userModel.name,
            'email': userModel.email,
            'phone': userModel.phone,
            'role': userModel.role.name,
            'avatarUrl': userModel.avatarUrl,
          }
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, stackTrace) {
      print('Me Error: $e');
      print(stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal Server Error: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> updateProfile(Request request) async {
    try {
      final userId = _requireUserId(request);
      if (userId == null) return _unauthorized();

      final payload = await request.readAsString();
      final body = jsonDecode(payload) as Map<String, dynamic>;
      final collection = await DatabaseService.getCollection('users');

      if (body['email'] != null) {
        final existing = await collection.findOne({
          'email': body['email'],
          '_id': {r'$ne': ObjectId.fromHexString(userId)},
        });
        if (existing != null) {
          return Response.badRequest(
            body: jsonEncode({'error': 'Email already exists'}),
            headers: {'content-type': 'application/json'},
          );
        }
      }

      final updates = <String, dynamic>{};
      if (body['name'] != null) updates['name'] = body['name'];
      if (body['email'] != null) updates['email'] = body['email'];
      if (body['phone'] != null) updates['phone'] = body['phone'];

      await collection.updateOne(
        {'_id': ObjectId.fromHexString(userId)},
        {r'$set': updates},
      );

      return Response.ok(
        jsonEncode({'message': 'Profile updated successfully'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, stackTrace) {
      print('Update Profile Error: $e');
      print(stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal Server Error: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> changePassword(Request request) async {
    try {
      final userId = _requireUserId(request);
      if (userId == null) return _unauthorized();

      final payload = await request.readAsString();
      final body = jsonDecode(payload) as Map<String, dynamic>;
      final collection = await DatabaseService.getCollection('users');

      final user = await collection.findOne({'_id': ObjectId.fromHexString(userId)});
      if (user == null) {
        return Response.notFound(
          jsonEncode({'error': 'User not found'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final currentHashed = AuthHelper.hashPassword(body['currentPassword']);
      if (user['password'] != currentHashed) {
        return Response.forbidden(
          jsonEncode({'error': 'Current password is incorrect'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final newHashed = AuthHelper.hashPassword(body['newPassword']);
      await collection.updateOne(
        {'_id': ObjectId.fromHexString(userId)},
        {r'$set': {'password': newHashed}},
      );

      return Response.ok(
        jsonEncode({'message': 'Password changed successfully'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, stackTrace) {
      print('Change Password Error: $e');
      print(stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal Server Error: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// Reset password by registered email/phone for the mock OTP flow.
  Future<Response> resetPassword(Request request) async {
    try {
      final payload = await request.readAsString();
      if (payload.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Request body cannot be empty'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final body = jsonDecode(payload) as Map<String, dynamic>;
      final contact = body['contact']?.toString().trim() ?? '';
      final newPassword = body['newPassword']?.toString() ?? '';
      if (contact.isEmpty || newPassword.length < 6) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Contact and a password of at least 6 characters are required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final collection = await DatabaseService.getCollection('users');
      final normalizedEmail = contact.toLowerCase();
      final user = await collection.findOne({
        r'$or': [
          {'email': normalizedEmail},
          {'phone': contact},
        ],
      });
      if (user == null) {
        return Response.notFound(
          jsonEncode({'error': 'No account found for this email or phone number'}),
          headers: {'content-type': 'application/json'},
        );
      }

      await collection.updateOne(
        {'_id': user['_id']},
        {r'$set': {'password': AuthHelper.hashPassword(newPassword)}},
      );

      return Response.ok(
        jsonEncode({'message': 'Password reset successfully'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, stackTrace) {
      print('Reset Password Error: $e');
      print(stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal Server Error: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> updateAvatar(Request request) async {
    try {
      final userId = _requireUserId(request);
      if (userId == null) return _unauthorized();

      final form = request.formData();
      if (form == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Expected multipart/form-data request'}),
          headers: {'content-type': 'application/json'},
        );
      }

      String? savedFileName;

      // អានផ្នែក multipart នីមួយៗតាមរយៈ form.formData
      await for (final formData in form.formData) {
        if (formData.name == 'avatar') {
          final mimeType = formData.part.headers['content-type'];
          final extension = _extensionFromContentType(mimeType);
          final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}$extension';
          final directory = Directory('uploads/avatars');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          final file = File('${directory.path}/$fileName');
          await formData.part.pipe(file.openWrite());
          savedFileName = fileName;
        } else {
          await formData.part.drain();
        }
      }

      if (savedFileName == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'No avatar file received'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final avatarUrl = '/uploads/avatars/$savedFileName';
      final collection = await DatabaseService.getCollection('users');
      await collection.updateOne(
        {'_id': ObjectId.fromHexString(userId)},
        {r'$set': {'avatarUrl': avatarUrl}},
      );

      return Response.ok(
        jsonEncode({'message': 'Avatar updated successfully', 'avatarUrl': avatarUrl}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, stackTrace) {
      print('Update Avatar Error: $e');
      print(stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal Server Error: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  String? _requireUserId(Request request) {
    final header = request.headers['authorization'];
    if (header == null || !header.startsWith('Bearer ')) return null;
    final token = header.substring(7);
    final jwt = AuthHelper.verifyToken(token);
    if (jwt == null) return null;
    final payload = jwt.payload as Map<String, dynamic>;
    return payload['id'] as String?;
  }

  Response _unauthorized() => Response.forbidden(
        jsonEncode({'error': 'Unauthorized'}),
        headers: {'content-type': 'application/json'},
      );

  String _extensionFromContentType(String? mimeType) {
    switch (mimeType) {
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      default:
        return '.jpg';
    }
  }
}
