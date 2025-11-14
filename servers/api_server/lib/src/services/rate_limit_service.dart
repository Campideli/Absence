// ignore_for_file: avoid_slow_async_io

import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';

final Logger _logger = Logger('RateLimitService');

class RateLimitService {
  static const String _rateLimitDir = '.rate_limits';
  static const int _maxRequestsPerMinute = 60;
  static const int _maxRequestsPerUserPerMinute = 30;
  static const int _blockDurationMinutes = 15;
  
  static Future<void> _ensureDirectoryExists() async {
    final dir = Directory(_rateLimitDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }
  
  static Future<Map<String, dynamic>> _loadRateLimitData(String key) async {
    try {
      await _ensureDirectoryExists();
      final file = File('$_rateLimitDir/$key.json');
      
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
      
      return {'requests': <String>[], 'blockedUntil': null};
    } catch (e) {
      _logger.warning('Erro ao carregar dados de rate limit para $key: $e');
      return {'requests': <String>[], 'blockedUntil': null};
    }
  }
  
  static Future<void> _saveRateLimitData(String key, Map<String, dynamic> data) async {
    try {
      await _ensureDirectoryExists();
      final file = File('$_rateLimitDir/$key.json');
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      _logger.warning('Erro ao salvar dados de rate limit para $key: $e');
    }
  }
  
  static Future<bool> checkRateLimit(String clientIp, {String? userId}) async {
    final now = DateTime.now();
    
    // Verificar rate limit por IP
    final ipLimitResult = await _checkIpRateLimit(clientIp, now);
    if (!ipLimitResult) {
      return false;
    }
    
    // Verificar rate limit por usuário (se autenticado)
    if (userId != null) {
      final userLimitResult = await _checkUserRateLimit(userId, now);
      if (!userLimitResult) {
        return false;
      }
    }
    
    return true;
  }
  
  static Future<bool> _checkIpRateLimit(String clientIp, DateTime now) async {
    final data = await _loadRateLimitData('ip_$clientIp');
    
    // Verificar se IP está bloqueado
    final blockedUntilStr = data['blockedUntil'] as String?;
    if (blockedUntilStr != null) {
      final blockedUntil = DateTime.parse(blockedUntilStr);
      if (now.isBefore(blockedUntil)) {
        _logger.warning('IP $clientIp bloqueado até ${blockedUntil.toIso8601String()}');
        return false;
      } else {
        // Remover bloqueio expirado
        data['blockedUntil'] = null;
      }
    }
    
    // Limpar requisições antigas e contar requisições recentes
    final requests = (data['requests'] as List<dynamic>)
        .cast<String>()
        .map(DateTime.parse)
        .where((time) => now.difference(time).inMinutes < 1)
        .toList();
    
    // Verificar limite
    if (requests.length >= _maxRequestsPerMinute) {
      // Bloquear IP
      data['blockedUntil'] = now.add(const Duration(minutes: _blockDurationMinutes)).toIso8601String();
      data['requests'] = <String>[];
      await _saveRateLimitData('ip_$clientIp', data);
      
      _logger.warning('IP $clientIp bloqueado por excesso de requisições');
      return false;
    }
    
    // Registrar nova requisição
    requests.add(now);
    data['requests'] = requests.map((time) => time.toIso8601String()).toList();
    await _saveRateLimitData('ip_$clientIp', data);
    
    return true;
  }
  
  static Future<bool> _checkUserRateLimit(String userId, DateTime now) async {
    final data = await _loadRateLimitData('user_$userId');
    
    // Limpar requisições antigas e contar requisições recentes
    final requests = (data['requests'] as List<dynamic>)
        .cast<String>()
        .map(DateTime.parse)
        .where((time) => now.difference(time).inMinutes < 1)
        .toList();
    
    // Verificar limite
    if (requests.length >= _maxRequestsPerUserPerMinute) {
      _logger.warning('Usuário $userId excedeu limite de requisições');
      return false;
    }
    
    // Registrar nova requisição
    requests.add(now);
    data['requests'] = requests.map((time) => time.toIso8601String()).toList();
    await _saveRateLimitData('user_$userId', data);
    
    return true;
  }
  
  static Future<String?> getBlockedUntil(String clientIp) async {
    final data = await _loadRateLimitData('ip_$clientIp');
    final blockedUntilStr = data['blockedUntil'] as String?;
    
    if (blockedUntilStr != null) {
      final blockedUntil = DateTime.parse(blockedUntilStr);
      if (DateTime.now().isBefore(blockedUntil)) {
        return blockedUntilStr;
      }
    }
    
    return null;
  }
  
  /// Limpeza de arquivos antigos (executar periodicamente)
  static Future<void> cleanupOldFiles() async {
    try {
      await _ensureDirectoryExists();
      final dir = Directory(_rateLimitDir);
      final now = DateTime.now();
      
      await for (final entity in dir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified);
          
          // Remover arquivos mais antigos que 1 hora
          if (age.inHours > 1) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      _logger.warning('Erro na limpeza de arquivos de rate limit: $e');
    }
  }
}