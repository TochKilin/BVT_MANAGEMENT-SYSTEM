import 'package:shelf/shelf.dart';
import '../utils/auth_helper.dart';

Middleware checkJwt() {
  return (Handler innerHandler) {
    return (Request request) async {
      // រំលងការឆែក Token សម្រាប់ Route Register/Login
      if (request.url.path.startsWith('api/auth/')) {
        return innerHandler(request);
      }

      final authHeader = request.headers['Authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.unauthorized('Missing or invalid Authorization header');
      }

      final token = authHeader.substring(7);
      final jwt = AuthHelper.verifyToken(token);

      if (jwt == null) {
        return Response.unauthorized('Invalid or expired Token');
      }

      // បន្ថែម User payload ចូលក្នុង Request context
      final updatedRequest = request.change(context: {'user': jwt.payload});
      return innerHandler(updatedRequest);
    };
  };
}