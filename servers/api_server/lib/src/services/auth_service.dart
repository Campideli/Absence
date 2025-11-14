import 'dart:convert';
import 'dart:math';

import 'package:api_server/src/services/logging_service.dart';
import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

final Logger _logger = Logger('AuthService');

class AuthService {
  static String? _projectId;
  static String? _firebasePrivateKey;
  static String? _firebaseClientEmail;
  static String? _firebaseWebApiKey;
  
  static Future<void> initialize() async {
    final env = DotEnv()..load();
    _projectId = env['FIREBASE_PROJECT_ID'];
    _firebasePrivateKey = env['FIREBASE_PRIVATE_KEY'];
    _firebaseClientEmail = env['FIREBASE_CLIENT_EMAIL'];
    _firebaseWebApiKey = env['FIREBASE_WEB_API_KEY'];
    
    if (_projectId == null || _firebasePrivateKey == null || _firebaseClientEmail == null) {
      throw Exception('Credenciais Firebase incompletas no .env');
    }
    
    _logger.info('AuthService inicializado para projeto');
  }
  
  /// Gera um correlation ID único para rastreamento de erros nos logs
  static String _generateCorrelationId() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = random.nextInt(999999).toString().padLeft(6, '0');
    return 'auth_${timestamp}_$randomPart';
  }
  
  /// Verifica token Firebase e retorna o userId usando verificação completa de assinatura
  static Future<String> verifyTokenAndGetUserId(String token) async {
    final correlationId = _generateCorrelationId();
    
    if (_projectId == null) {
      await initialize();
    }
    
    try {
      _logger.info('[$correlationId] Verificando token Firebase com validação completa...');
      
      // Validar estrutura do JWT
      final parts = token.split('.');
      if (parts.length != 3) {
        _logger.warning('[$correlationId] Token JWT mal formado');
        throw Exception('Authentication failed');
      }
      
      // Decodificar header para obter algoritmo e key ID
      final headerBase64 = parts[0];
      final normalizedHeader = headerBase64.padRight(
        (headerBase64.length + 3) ~/ 4 * 4, 
        '=',
      );
      final headerJson = utf8.decode(base64Url.decode(normalizedHeader));
      final header = jsonDecode(headerJson) as Map<String, dynamic>;
      
      final alg = header['alg'] as String?;
      final kid = header['kid'] as String?;
      
      if (alg != 'RS256') {
        _logger.warning('[$correlationId] Algoritmo não suportado: $alg');
        throw Exception('Authentication failed');
      }
      
      if (kid == null) {
        _logger.warning('[$correlationId] Key ID não encontrado no header');
        throw Exception('Authentication failed');
      }
      
      // Verificar token via Firebase API (método mais confiável)
      final isValid = await _verifyTokenViaFirebaseAPI(token, correlationId);
      
      if (!isValid) {
        _logger.warning('[$correlationId] Token rejeitado pela API Firebase');
        throw Exception('Authentication failed');
      }
      
      _logger.info('[$correlationId] Token validado com sucesso pela API Firebase');
      
      // Decodificar payload apenas após verificação da assinatura
      final payloadBase64 = parts[1];
      final normalizedPayload = payloadBase64.padRight(
        (payloadBase64.length + 3) ~/ 4 * 4, 
        '=',
      );
      
      final payloadJson = utf8.decode(base64Url.decode(normalizedPayload));
      final payloadData = jsonDecode(payloadJson) as Map<String, dynamic>;
      
      _logger.info('[$correlationId] Token decodificado com sucesso');
      
      // Verificar audience (deve ser o project ID)
      final aud = payloadData['aud'] as String?;
      if (aud != _projectId) {
        _logger.warning('[$correlationId] Token com audience inválido: $aud != $_projectId');
        throw Exception('Authentication failed');
      }
      
      // Verificar issuer
      final iss = payloadData['iss'] as String?;
      final expectedIss = 'https://securetoken.google.com/$_projectId';
      if (iss != expectedIss) {
        _logger.warning('[$correlationId] Token com issuer inválido: $iss != $expectedIss');
        throw Exception('Authentication failed');
      }
      
      // Verificar expiração
      final exp = payloadData['exp'] as int?;
      if (exp == null || DateTime.fromMillisecondsSinceEpoch(exp * 1000).isBefore(DateTime.now())) {
        _logger.warning('[$correlationId] Token expirado');
        throw Exception('Authentication failed');
      }
      
      // Extrair userId (sub claim)
      final userId = payloadData['sub'] as String?;
      if (userId == null || userId.isEmpty) {
        _logger.warning('[$correlationId] Token sem userId válido');
        throw Exception('Authentication failed');
      }
      
      _logger.info('[$correlationId] Token Firebase verificado com sucesso para userId: $userId');
      
      // Log de auditoria
      LoggingService.auditLog('JWT_VERIFIED', userId, metadata: {
        'correlationId': correlationId,
        'issuer': iss,
        'audience': aud,
      });
      
      return userId;
      
    } catch (e) {
      _logger.warning('[$correlationId] Erro na verificação do token Firebase: ${e.toString()}');
      
      // SECURITY: SEMPRE retornar mensagem genérica, independente do ambiente
      // Detalhes do erro estão apenas nos logs server-side com correlation ID
      throw Exception('Authentication failed');
    }
  }
  
  /// Verifica token via API do Firebase
  static Future<bool> _verifyTokenViaFirebaseAPI(String token, String correlationId) async {
    try {
      if (_firebaseWebApiKey == null) {
        _logger.warning('[$correlationId] Firebase Web API Key não configurada');
        return false;
      }
      
      final url = 'https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=$_firebaseWebApiKey';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': token}),
      );
      
      _logger.info('[$correlationId] Firebase API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final users = responseData['users'] as List<dynamic>?;
        
        if (users != null && users.isNotEmpty) {
          _logger.info('[$correlationId] Token verificado com sucesso via Firebase API');
          return true;
        } else {
          _logger.warning('[$correlationId] Resposta da API Firebase sem usuários válidos');
          return false;
        }
      } else {
        // SECURITY: Não logar corpo da resposta completo (pode conter dados sensíveis)
        _logger.warning('[$correlationId] Falha na verificação via Firebase API: ${response.statusCode}');
        return false;
      }
      
    } catch (e) {
      _logger.warning('[$correlationId] Erro na verificação via API Firebase: ${e.toString()}');
      return false;
    }
  }
  
  /// Extrai userId do token sem validação completa (apenas para casos específicos)
  static String? extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final normalizedPayload = payload.padRight(
          (payload.length + 3) ~/ 4 * 4, 
          '=',
        );
        
        final decoded = utf8.decode(base64Url.decode(normalizedPayload));
        final payloadData = jsonDecode(decoded) as Map<String, dynamic>;
        
        return payloadData['sub'] as String?;
      }
    } catch (e) {
      _logger.warning('Erro ao extrair userId do token: $e');
    }
    
    return null;
  }
}
