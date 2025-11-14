import 'dart:io';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

class LoggingMiddleware {
  static final Logger _logger = Logger('HTTP');

  /// Middleware para logging de requisições HTTP
  static Middleware logging() {
    return (innerHandler) {
      return (request) async {
        final startTime = DateTime.now();
        final method = request.method;
        final uri = request.requestedUri;
        final ip = _getClientIp(request);

        _logger.info('→ $method $uri from $ip');

        try {
          final response = await innerHandler(request);
          final duration = DateTime.now().difference(startTime).inMilliseconds;
          
          _logger.info(
            '← ${response.statusCode} $method $uri ${duration}ms',
          );

          return response;
        } catch (error, stackTrace) {
          final duration = DateTime.now().difference(startTime).inMilliseconds;
          
          _logger.severe(
            '✗ ERROR $method $uri ${duration}ms: $error',
            error,
            stackTrace,
          );
          
          rethrow;
        }
      };
    };
  }

  /// Middleware mais detalhado para desenvolvimento
  static Middleware detailed() {
    return (innerHandler) {
      return (request) async {
        final startTime = DateTime.now();
        final method = request.method;
        final uri = request.requestedUri;
        final userAgent = request.headers['user-agent'] ?? 'Unknown';
        final ip = _getClientIp(request);
        final contentType = request.headers['content-type'];
        final contentLength = request.headers['content-length'];

        _logger.info(
          '→ $method $uri\n'
          '  IP: $ip\n'
          '  User-Agent: $userAgent\n'
          '  Content-Type: $contentType\n'
          '  Content-Length: $contentLength\n'
          '  Headers: ${request.headers}',
        );

        try {
          final response = await innerHandler(request);
          final duration = DateTime.now().difference(startTime).inMilliseconds;
          
          _logger.info(
            '← ${response.statusCode} $method $uri ${duration}ms\n'
            '  Response Headers: ${response.headers}',
          );

          return response;
        } catch (error, stackTrace) {
          final duration = DateTime.now().difference(startTime).inMilliseconds;
          
          _logger.severe(
            '✗ ERROR $method $uri ${duration}ms\n'
            '  Error: $error\n'
            '  Stack: $stackTrace',
            error,
            stackTrace,
          );
          
          rethrow;
        }
      };
    };
  }

  /// Extrai o IP do cliente da requisição
  static String _getClientIp(Request request) {
    // Verifica headers de proxy
    final xForwardedFor = request.headers['x-forwarded-for'];
    if (xForwardedFor != null) {
      return xForwardedFor.split(',').first.trim();
    }

    final xRealIp = request.headers['x-real-ip'];
    if (xRealIp != null) {
      return xRealIp;
    }

    // Fallback para conexão direta
    try {
      final connectionInfo = request.context['shelf.io.connection_info'] as HttpConnectionInfo?;
      if (connectionInfo != null) {
        return connectionInfo.remoteAddress.address;
      }
    } catch (e) {
      // Ignora erro se não conseguir acessar connection info
    }
    
    return 'Unknown';
  }
}
