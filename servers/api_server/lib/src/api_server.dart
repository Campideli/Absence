import 'dart:io';

import 'package:api_server/src/config/server_config.dart';
import 'package:api_server/src/middleware/auth_middleware.dart';
import 'package:api_server/src/middleware/cors_middleware.dart';
import 'package:api_server/src/middleware/logging_middleware.dart';
import 'package:api_server/src/middleware/security_middleware.dart';
import 'package:api_server/src/routes/api_routes.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

class ApiServer {
  ApiServer(this.config);

  final ServerConfig config;
  final Logger _logger = Logger('ApiServer');
  HttpServer? _server;

  Future<void> start() async {
    try {
      // Initialize API routes with config
      ApiRoutes.initialize(config);

      // Configure middleware pipeline - ordem importa para segurança
      final handler = const Pipeline()
          .addMiddleware(LoggingMiddleware.logging())
          .addMiddleware(SecurityMiddleware.securityHeaders())
          .addMiddleware(SecurityMiddleware.rateLimit())
          .addMiddleware(_corsMiddleware())
          .addMiddleware(AuthMiddleware.handle())
          .addHandler(ApiRoutes.router.call);

      // Start server
      _server = await shelf_io.serve(
        handler,
        config.host,
        config.port,
      );

      _logger.info('Server listening on ${config.host}:${config.port}');
      _logger.info('Environment: ${config.environment}');
      _logger.info('Server started successfully on port ${config.port}');
    } catch (e) {
      _logger.severe('Failed to start server: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    if (_server != null) {
      await _server!.close();
      _logger.info('Server stopped');
    }
  }

  Middleware _corsMiddleware() {
    if (!config.enableCors) {
      return (Handler handler) => handler;
    }

    return CorsMiddleware.cors(
      allowedOrigins: config.safeAllowedOrigins,
      isProduction: config.isProduction,
    );
  }
}
