import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../security/security_service.dart';
import '../../config/env_config.dart';

class HttpService {
  static String get _baseUrl {
    final apiUrl = EnvConfig.apiBaseUrl;
    return '$apiUrl/api/v1';
  }
  
  final SecurityService _securityService = SecurityService();

  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  HttpService._internal();

  /// Headers padrão para todas as requisições
  Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Headers com autenticação
  Future<Map<String, String>> get _authHeaders async {
    final headers = Map<String, String>.from(_defaultHeaders);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      headers['Authorization'] = 'Bearer $token';
    } else {
      throw Exception('Usuário não autenticado. É necessário fazer login para usar a API.');
    }
    
    return headers;
  }

  /// Valida e sanitiza dados de entrada
  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    return _securityService.sanitizeInput(data);
  }

  /// Processa resposta e trata erros
  Map<String, dynamic> _processResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      throw UnauthorizedException('Token de autenticação inválido ou expirado');
    } else if (response.statusCode == 403) {
      throw ForbiddenException('Acesso negado');
    } else if (response.statusCode == 404) {
      throw NotFoundException('Recurso não encontrado');
    } else if (response.statusCode == 422) {
      final errorData = json.decode(response.body) as Map<String, dynamic>;
      throw ValidationException(errorData['error'] ?? 'Dados inválidos');
    } else if (response.statusCode >= 500) {
      throw ServerException('Erro interno do servidor');
    } else {
      final errorData = json.decode(response.body) as Map<String, dynamic>;
      throw ApiHttpException(
        errorData['error'] ?? 'Erro desconhecido',
        response.statusCode,
      );
    }
  }

  /// GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
      );
      
      return _processResponse(response);
    } catch (e) {
      if (e is HttpException) rethrow;
      throw NetworkException('Erro de conexão: $e');
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _authHeaders;
      final sanitizedData = _sanitizeData(data);
      
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
        body: json.encode(sanitizedData),
      );
      
      return _processResponse(response);
    } catch (e) {
      if (e is HttpException) rethrow;
      throw NetworkException('Erro de conexão: $e');
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _authHeaders;
      final sanitizedData = _sanitizeData(data);
      
      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
        body: json.encode(sanitizedData),
      );
      
      return _processResponse(response);
    } catch (e) {
      if (e is HttpException) rethrow;
      throw NetworkException('Erro de conexão: $e');
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final headers = await _authHeaders;
      final response = await http.delete(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
      );
      
      return _processResponse(response);
    } catch (e) {
      if (e is HttpException) rethrow;
      throw NetworkException('Erro de conexão: $e');
    }
  }

  /// Verifica se o servidor está online
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl.replaceAll('/api/v1', '')}/health'),
        headers: _defaultHeaders,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// Exceções customizadas
abstract class HttpException implements Exception {
  final String message;
  final int? statusCode;
  
  const HttpException(this.message, [this.statusCode]);
  
  @override
  String toString() => 'HttpException: $message';
}

class UnauthorizedException extends HttpException {
  const UnauthorizedException(String message) : super(message, 401);
}

class ForbiddenException extends HttpException {
  const ForbiddenException(String message) : super(message, 403);
}

class NotFoundException extends HttpException {
  const NotFoundException(String message) : super(message, 404);
}

class ValidationException extends HttpException {
  const ValidationException(String message) : super(message, 422);
}

class ServerException extends HttpException {
  const ServerException(String message) : super(message, 500);
}

class NetworkException extends HttpException {
  const NetworkException(super.message);
}

class ApiHttpException extends HttpException {
  const ApiHttpException(super.message, super.statusCode);
}
