import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

class LoggingService {
  static bool _initialized = false;
  static String _environment = 'development';
  static Level _logLevel = Level.INFO;
  
  static Future<void> initialize() async {
    if (_initialized) return;
    
    final env = Platform.environment;
    _environment = env['ENVIRONMENT'] ?? 'development';
    
    // Configurar nível de log baseado no ambiente
    final logLevelStr = env['LOG_LEVEL'] ?? 'INFO';
    _logLevel = _parseLogLevel(logLevelStr);
    
    // Configurar o logger global
    Logger.root.level = _logLevel;
    Logger.root.onRecord.listen(_logHandler);
    
    _initialized = true;
    Logger('LoggingService').info('Logging configurado para ambiente: $_environment, nível: $_logLevel');
  }
  
  static Level _parseLogLevel(String levelStr) {
    switch (levelStr.toUpperCase()) {
      case 'FINEST':
        return Level.FINEST;
      case 'FINER':
        return Level.FINER;
      case 'FINE':
        return Level.FINE;
      case 'CONFIG':
        return Level.CONFIG;
      case 'INFO':
        return Level.INFO;
      case 'WARNING':
        return Level.WARNING;
      case 'SEVERE':
        return Level.SEVERE;
      case 'SHOUT':
        return Level.SHOUT;
      default:
        return Level.INFO;
    }
  }
  
  static void _logHandler(LogRecord record) {
    final isProduction = _environment == 'production';
    
    // Filtrar logs sensíveis em produção
    if (isProduction && _containsSensitiveInfo(record.message)) {
      return; // Não logar informações sensíveis em produção
    }
    
    // Formato do log
    final timestamp = record.time.toIso8601String();
    final level = record.level.name.padRight(7);
    final logger = record.loggerName.length > 20 
        ? '...${record.loggerName.substring(record.loggerName.length - 17)}'
        : record.loggerName.padRight(20);
    
    var message = record.message;
    
    // Sanitizar mensagem se necessário
    if (isProduction) {
      message = _sanitizeLogMessage(message);
    }
    
    // Formato: [TIMESTAMP] [LEVEL] [LOGGER] MESSAGE
    final logLine = '[$timestamp] [$level] [$logger] $message';
    
    // Output baseado no nível
    if (record.level >= Level.SEVERE) {
      stderr.writeln('\x1B[31m$logLine\x1B[0m'); // Vermelho para erros
    } else if (record.level >= Level.WARNING) {
      stdout.writeln('\x1B[33m$logLine\x1B[0m'); // Amarelo para warnings
    } else if (record.level >= Level.INFO) {
      stdout.writeln('\x1B[36m$logLine\x1B[0m'); // Ciano para info
    } else {
      stdout.writeln(logLine); // Sem cor para debug
    }
    
    // Adicionar stack trace para erros em desenvolvimento
    if (!isProduction && record.error != null) {
      stderr.writeln('Error: ${record.error}');
    }
    
    if (!isProduction && record.stackTrace != null) {
      stderr.writeln('Stack trace:\n${record.stackTrace}');
    }
  }
  
  static bool _containsSensitiveInfo(String message) {
    final sensitivePatterns = [
      RegExp(r'token["\s:=][^"\s,}]+', caseSensitive: false),
      RegExp(r'password["\s:=][^"\s,}]+', caseSensitive: false),
      RegExp(r'key["\s:=][^"\s,}]+', caseSensitive: false),
      RegExp(r'secret["\s:=][^"\s,}]+', caseSensitive: false),
      RegExp(r'firebase["\s:=][^"\s,}]+', caseSensitive: false),
      RegExp(r'Bearer\s+[A-Za-z0-9\-_\.]+', caseSensitive: false),
      RegExp(r'[A-Za-z0-9]{50,}'), // Tokens longos
    ];
    
    return sensitivePatterns.any((pattern) => pattern.hasMatch(message));
  }
  
  static String _sanitizeLogMessage(String message) {
    var sanitized = message;
    
    // Substituir tokens e chaves por placeholders
    sanitized = sanitized.replaceAll(
      RegExp(r'(token["\s:=])([^"\s,}]+)', caseSensitive: false),
      r'$1***TOKEN***',
    );
    
    sanitized = sanitized.replaceAll(
      RegExp(r'(password["\s:=])([^"\s,}]+)', caseSensitive: false),
      r'$1***PASSWORD***',
    );
    
    sanitized = sanitized.replaceAll(
      RegExp(r'(key["\s:=])([^"\s,}]+)', caseSensitive: false),
      r'$1***KEY***',
    );
    
    sanitized = sanitized.replaceAll(
      RegExp(r'Bearer\s+[A-Za-z0-9\-_\.]+', caseSensitive: false),
      'Bearer ***TOKEN***',
    );
    
    sanitized = sanitized.replaceAll(
      RegExp(r'[A-Za-z0-9]{50,}'),
      '***LONG_TOKEN***',
    );
    
    return sanitized;
  }
  
  /// Log de auditoria para ações importantes
  static void auditLog(String action, String userId, {Map<String, dynamic>? metadata}) {
    final auditData = {
      'action': action,
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
    };
    
    final logger = Logger('AUDIT');
    logger.info('AUDIT: ${jsonEncode(auditData)}');
  }
  
  /// Log de segurança para eventos suspeitos
  static void securityLog(String event, String? clientIp, {Map<String, dynamic>? details}) {
    final securityData = {
      'event': event,
      'clientIp': clientIp,
      'timestamp': DateTime.now().toIso8601String(),
      'details': details ?? {},
    };
    
    final logger = Logger('SECURITY');
    logger.warning('SECURITY: ${jsonEncode(securityData)}');
  }
  
  /// Verifica se está em produção
  static bool get isProduction => _environment == 'production';
  
  /// Verifica se está em desenvolvimento
  static bool get isDevelopment => _environment == 'development';
}