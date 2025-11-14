import 'package:api_server/src/config/server_config.dart';
import 'package:api_server/src/routes/absence_routes.dart';
import 'package:api_server/src/routes/schedule_routes.dart';
import 'package:api_server/src/routes/subject_routes.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class ApiRoutes {
  static late ServerConfig _config;

  static void initialize(ServerConfig config) {
    _config = config;
  }

  static Router get router {
    final router = Router();

    // Health check
    router.get('/health', _healthCheck);

    // API v1 routes
    router.mount('/api/v1/', _apiV1Routes().call);

    // Catch all - 404
    router.all('/<ignored|.*>', _notFound);

    return router;
  }

  static Router _apiV1Routes() {
    final router = Router();
    // Monta rotas separadas por domínio
    router.mount('/', subjectRoutes().call);
    router.mount('/', absenceRoutes().call);
    router.mount('/', scheduleRoutes(_config.pdfServiceUrl).call);
    return router;
  }

  static Response _healthCheck(Request request) {
    return Response.ok(
      '{"status": "healthy", "timestamp": "${DateTime.now().toIso8601String()}"}',
      headers: {'Content-Type': 'application/json'},
    );
  }


  static Response _notFound(Request request) {
    return Response.notFound(
      '{"error": "Endpoint not found", "path": "${request.requestedUri.path}"}',
      headers: {'Content-Type': 'application/json'},
    );
  }
}
