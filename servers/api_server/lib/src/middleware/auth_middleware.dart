import 'dart:convert';

import 'package:api_server/src/models/api_response.dart';
import 'package:api_server/src/services/auth_service.dart';
import 'package:shelf/shelf.dart';

class AuthMiddleware {
  /// Middleware para verificar autenticação Firebase
  static Middleware handle() {
    return (Handler innerHandler) {
      return (Request request) async {
        // Verificar se a rota precisa de autenticação
        final path = request.url.path;
        
        // Rotas públicas específicas (lista restritiva)
        final publicRoutes = {
          'health',
        };
        
        final isPublicRoute = publicRoutes.any((route) => path == route);
        
        if (isPublicRoute) {
          return await innerHandler(request);
        }
        
        // Extrair token do header Authorization
        final authHeader = request.headers['authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          return Response(
            401,
            body: jsonEncode(ApiResponse.error(
              message: 'Token de acesso requerido',
              code: 401,
            ).toJson((data) => data)),
            headers: {'Content-Type': 'application/json'},
          );
        }

        final token = authHeader.substring(7); // Remove "Bearer "
        
        // Validação básica do token antes de enviar para verificação
        if (token.isEmpty || token.length < 10) {
          return Response(
            401,
            body: jsonEncode(ApiResponse.error(
              message: 'Token de acesso inválido',
              code: 401,
            ).toJson((data) => data)),
            headers: {'Content-Type': 'application/json'},
          );
        }        try {
          // Verificar token e extrair userId
          final userId = await AuthService.verifyTokenAndGetUserId(token);
          
          // Adicionar userId ao context do request
          final updatedRequest = request.change(context: {
            ...request.context,
            'userId': userId,
          });
          
          return await innerHandler(updatedRequest);
        } catch (e) {
          return Response(
            401,
            body: jsonEncode(ApiResponse.error(
              message: 'Token de acesso inválido',
              code: 401,
            ).toJson((data) => data)),
            headers: {'Content-Type': 'application/json'},
          );
        }
      };
    };
  }
  
  /// Extrai o userId do context do request
  static String? getUserId(Request request) {
    return request.context['userId'] as String?;
  }
  
  /// Extrai o email do usuário do context do request
  static String? getUserEmail(Request request) {
    return request.context['userEmail'] as String?;
  }
}
