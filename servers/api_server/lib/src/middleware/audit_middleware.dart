import 'package:api_server/src/services/logging_service.dart';
import 'package:shelf/shelf.dart';

class AuditMiddleware {
  /// Middleware para logs de auditoria de ações dos usuários
  static Middleware auditMiddleware() {
    return (Handler handler) {
      return (Request request) async {
        final userId = request.context['userId'] as String?;
        final method = request.method;
        final path = request.url.path;
        final userAgent = request.headers['user-agent'];
        final clientIp = _getClientIp(request);
        
        // Capturar timestamp de início
        final startTime = DateTime.now();
        
        try {
          // Executar request
          final response = await handler(request);
          
          // Log de auditoria para ações autenticadas
          if (userId != null && _shouldAudit(method, path)) {
            final duration = DateTime.now().difference(startTime).inMilliseconds;
            
            LoggingService.auditLog(
              'API_REQUEST',
              userId,
              metadata: {
                'method': method,
                'path': path,
                'statusCode': response.statusCode,
                'clientIp': clientIp,
                'userAgent': userAgent,
                'duration': duration,
              },
            );
          }
          
          // Log de segurança para falhas de autenticação
          if (response.statusCode == 401) {
            LoggingService.securityLog(
              'UNAUTHORIZED_ACCESS',
              clientIp,
              details: {
                'method': method,
                'path': path,
                'userAgent': userAgent,
              },
            );
          }
          
          // Log de segurança para muitas requisições
          if (response.statusCode == 429) {
            LoggingService.securityLog(
              'RATE_LIMIT_EXCEEDED',
              clientIp,
              details: {
                'method': method,
                'path': path,
                'userAgent': userAgent,
                'userId': userId,
              },
            );
          }
          
          return response;
          
        } catch (error) {
          // Log de erro
          LoggingService.securityLog(
            'REQUEST_ERROR',
            clientIp,
            details: {
              'method': method,
              'path': path,
              'error': error.toString(),
              'userId': userId,
            },
          );
          
          rethrow;
        }
      };
    };
  }
  
  /// Determina se a ação deve ser auditada
  static bool _shouldAudit(String method, String path) {
    // Auditar todas as operações de escrita
    if (method == 'POST' || method == 'PUT' || method == 'DELETE') {
      return true;
    }
    
    // Auditar leitura de dados sensíveis
    final sensitiveEndpoints = [
      'subjects',
      'absences',
      'users',
    ];
    
    return sensitiveEndpoints.any((endpoint) => path.contains(endpoint));
  }
  
  /// Extrai IP real do cliente
  static String _getClientIp(Request request) {
    return request.headers['x-forwarded-for']?.split(',').first.trim() ??
           request.headers['x-real-ip'] ??
           request.headers['cf-connecting-ip'] ??
           '127.0.0.1';
  }
}