import 'package:shelf/shelf.dart';

class CorsMiddleware {

  /// Configura middleware CORS baseado nas origens permitidas
  static Middleware cors({
    required List<String> allowedOrigins,
    required bool isProduction,
  }) {
    // Validações de segurança para produção
    if (isProduction) {
      for (final origin in allowedOrigins) {
        if (origin == '*') {
          throw Exception('Wildcard não permitido em produção');
        }
        if (origin.contains('localhost') || origin.contains('127.0.0.1')) {
          throw Exception('Localhost não permitido em produção');
        }
      }
    }

    return (Handler handler) {
      return (Request request) async {
        final origin = request.headers['origin'];
        final allowedOrigin = _getAllowedOrigin(origin, allowedOrigins, isProduction);
        
        // Para requisições OPTIONS, retornar headers CORS diretamente
        if (request.method == 'OPTIONS') {
          return Response.ok(
            '',
            headers: {
              'Access-Control-Allow-Origin': allowedOrigin,
              'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
              'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Requested-With,Accept,Origin',
              'Access-Control-Allow-Credentials': 'true',
              'Access-Control-Max-Age': '86400',
            },
          );
        }

        // Para outras requisições, processar normalmente e adicionar headers CORS
        final response = await handler(request);
        
        return response.change(headers: {
          'Access-Control-Allow-Origin': allowedOrigin,
          'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Requested-With,Accept,Origin',
          'Access-Control-Allow-Credentials': 'true',
          'Access-Control-Max-Age': '86400',
          ...response.headers,
        });
      };
    };
  }

  /// Determina a origem permitida baseada na requisição e configuração
  static String _getAllowedOrigin(String? requestOrigin, List<String> allowedOrigins, bool isProduction) {
    if (!isProduction) {
      // Em desenvolvimento, permitir qualquer origem localhost
      if (requestOrigin != null && 
          (requestOrigin.contains('localhost') || requestOrigin.contains('127.0.0.1'))) {
        return requestOrigin;
      }
    }
    
    // Verificar se a origem está na lista permitida
    if (requestOrigin != null && allowedOrigins.contains(requestOrigin)) {
      return requestOrigin;
    }
    
    // Fallback seguro - não permitir origem se não estiver na lista
    return allowedOrigins.isNotEmpty ? allowedOrigins.first : 'null';
  }
}
