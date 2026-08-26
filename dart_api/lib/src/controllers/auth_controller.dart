import 'dart:convert';
import 'package:shelf/shelf.dart';
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
      print('❌ Register Error: $e');
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
            'role': userModel.role.name,
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
}