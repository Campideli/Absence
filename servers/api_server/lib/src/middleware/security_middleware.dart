import 'package:api_server/src/services/logging_service.dart';
import 'package:api_server/src/services/rate_limit_service.dart';
import 'package:shelf/shelf.dart';

class SecurityMiddleware {
  /// Adiciona headers de segurança essenciais
  static Middleware securityHeaders() {
    return (Handler handler) {
      return (Request request) async {
        final response = await handler(request);
        
        return response.change(headers: {
          // Previne ataques XSS
          'X-XSS-Protection': '1; mode=block',
          // Previne clickjacking
          'X-Frame-Options': 'DENY',
          // Previne MIME type sniffing
          'X-Content-Type-Options': 'nosniff',
          // Política de referrer restritiva
          'Referrer-Policy': 'strict-origin-when-cross-origin',
          // CSP específico para Firebase e Google OAuth
          'Content-Security-Policy': [
            'default-src \'self\'',
            'script-src \'self\' \'unsafe-inline\' https://apis.google.com https://www.gstatic.com',
            'connect-src \'self\' https://*.googleapis.com https://*.firebase.com https://identitytoolkit.googleapis.com',
            'frame-src https://accounts.google.com',
            'img-src \'self\' data: https:',
            'style-src \'self\' \'unsafe-inline\' https://fonts.googleapis.com',
            'font-src \'self\' https://fonts.gstatic.com'
          ].join('; '),
          // Remove headers que revelam informações do servidor
          'Server': '',
          'X-Powered-By': '',
          // Força HTTPS em produção
          'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
          ...response.headers,
        });
      };
    };
  }

  /// Rate limiting persistente com armazenamento em arquivo
  static Middleware rateLimit() {
    return (Handler handler) {
      return (Request request) async {
        final clientIp = _getClientIp(request);
        final userId = request.context['userId'] as String?;
        
        // Verificar se IP está bloqueado
        final blockedUntil = await RateLimitService.getBlockedUntil(clientIp);
        if (blockedUntil != null) {
          final blockedUntilTime = DateTime.parse(blockedUntil);
          final minutesLeft = blockedUntilTime.difference(DateTime.now()).inMinutes;
          return Response(
            429,
            body: '{"error": "IP temporariamente bloqueado. Tente novamente em $minutesLeft minutos"}',
            headers: {'Content-Type': 'application/json'},
          );
        }
        
        // Verificar limites de rate
        final allowed = await RateLimitService.checkRateLimit(clientIp, userId: userId);
        
        if (!allowed) {
          var message = 'Muitas requisições';
          if (userId != null) {
            message = 'Muitas requisições do mesmo usuário';
          } else {
            message = 'Muitas requisições do mesmo IP';
          }
          
          return Response(
            429,
            body: '{"error": "$message"}',
            headers: {'Content-Type': 'application/json'},
          );
        }
        
        return await handler(request);
      };
    };
  }
  
  static String _getClientIp(Request request) {
    // Tenta obter o IP real através de headers de proxy
    return request.headers['x-forwarded-for']?.split(',').first.trim() ??
           request.headers['x-real-ip'] ??
           request.headers['cf-connecting-ip'] ?? // Cloudflare
           '127.0.0.1'; // Fallback para desenvolvimento
  }
  
  /// Middleware para validação de input e prevenção de ataques
  static Middleware inputValidation() {
    return (Handler handler) {
      return (Request request) async {
        final contentType = request.headers['content-type'];
        final clientIp = _getClientIp(request);
        
        // Verificar tamanho do body
        if (request.contentLength != null && request.contentLength! > 1024 * 1024) { // 1MB
          LoggingService.securityLog(
            'LARGE_PAYLOAD_DETECTED',
            clientIp,
            details: {
              'contentLength': request.contentLength,
              'method': request.method,
              'path': request.url.path,
            },
          );
          
          return Response(
            413,
            body: '{"error": "Payload muito grande"}',
            headers: {'Content-Type': 'application/json'},
          );
        }
        
        // Verificar Content-Type para requests com body
        if ((request.method == 'POST' || request.method == 'PUT' || request.method == 'PATCH') &&
            contentType != null && !contentType.contains('application/json')) {
          return Response(
            415,
            body: '{"error": "Content-Type não suportado"}',
            headers: {'Content-Type': 'application/json'},
          );
        }
        
        // Verificar padrões maliciosos no body para requests POST/PUT/PATCH
        if (request.method == 'POST' || request.method == 'PUT' || request.method == 'PATCH') {
          final body = await request.readAsString();
          
          if (_containsMaliciousPatterns(body)) {
            LoggingService.securityLog(
              'MALICIOUS_INPUT_DETECTED',
              clientIp,
              details: {
                'method': request.method,
                'path': request.url.path,
                'bodyLength': body.length,
                'userId': request.context['userId'],
              },
            );
            
            return Response(
              400,
              body: '{"error": "Input inválido detectado"}',
              headers: {'Content-Type': 'application/json'},
            );
          }
          
          // Reconstruir request com body lido
          return await handler(
            request.change(body: body),
          );
        }
        
        return await handler(request);
      };
    };
  }
  
  /// Verifica se o conteúdo contém padrões maliciosos
  static bool _containsMaliciousPatterns(String content) {
    final maliciousPatterns = [
      // SQL Injection (mantido por prevenção, embora não use SQL)
      RegExp(r"(\'\s*(or|and)\s*\'\s*=\s*\')", caseSensitive: false),
      RegExp(r'(\-\-|\#|\/\*|\*\/)', caseSensitive: false),
      RegExp(r'(union\s+select|drop\s+table|delete\s+from)', caseSensitive: false),
      
      // XSS Attempts
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
      RegExp(r'javascript\s*:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'<iframe[^>]*>', caseSensitive: false),
      
      // Path Traversal
      RegExp(r'(\.\./|\.\.\\\|%2e%2e%2f)', caseSensitive: false),
      
      // Command Injection
      RegExp(r'(;\s*(?:rm|cat|ls|pwd|whoami|id|uname))', caseSensitive: false),
      RegExp(r'(\|\s*(?:nc|netcat|curl|wget))', caseSensitive: false),
      
      // SECURITY FIX: Removida validação de NoSQL Injection MongoDB
      // Firestore usa SDK diferente e não é vulnerável aos mesmos operadores
      // A sanitização de input é feita no InputSanitizer service
      
      // LDAP Injection
      RegExp(r'(\*\)|\(\|)', caseSensitive: false),
      
      // Template Injection
      RegExp(r'(\{\{.*\}\}|\{%.*%\})', caseSensitive: false),
      
      // Null bytes e caracteres de controle (já sanitizado no InputSanitizer)
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'),
      
      // Strings muito longas que podem indicar buffer overflow
      RegExp(r'.{5000,}'), // Strings maiores que 5000 caracteres
    ];
    
    return maliciousPatterns.any((pattern) => pattern.hasMatch(content));
  }
}