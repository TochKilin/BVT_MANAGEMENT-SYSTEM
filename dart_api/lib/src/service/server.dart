import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import '../routes/app_router.dart';

Future<HttpServer> startServer({int port = 8585}) async {
  final handler = Pipeline()
      .addMiddleware(_cors())
      .addMiddleware(logRequests())
      .addHandler(AppRouter().router.call);

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('Server running at http://${server.address.host}:${server.port}');
  return server;
}

Future<void> main() async {
  await startServer();
}

Middleware _cors() => (Handler innerHandler) => (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final response = await innerHandler(request);
      return response.change(headers: {...response.headers, ..._corsHeaders});
    };

const _corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'access-control-allow-headers': 'Origin, Content-Type, Authorization',
};
