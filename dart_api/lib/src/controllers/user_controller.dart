import 'dart:convert';
import 'package:shelf/shelf.dart';

class UserController {

  Response getHome(Request request) {
    return Response.ok('ស្វាគមន៍មកកាន់ Dart API របស់អ្នក!');
  }

  Response getUsers(Request request) {
    final users = [
      {'id': 1, 'name': 'Sokwwwwww', 'role': 'Admin'},
      {'id': 2, 'name': 'Sao', 'role': 'User'},
    ];

    return Response.ok(
      jsonEncode(users),
      headers: {'content-type': 'application/json'},
    );
  }
}