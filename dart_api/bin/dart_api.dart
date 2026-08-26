import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:dart_api/src/routes/app_router.dart';

void main() async {
 
  final appRouter = AppRouter();

  final handler = Pipeline()
      .addMiddleware(_cors())
      .addMiddleware(logRequests())
      .addHandler(appRouter.router.call);

  final server = await shelf_io.serve(handler, '0.0.0.0', 8585);
  print('Server កំពុងដំណើរការលើ: http://${server.address.host}:${server.port}');
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
