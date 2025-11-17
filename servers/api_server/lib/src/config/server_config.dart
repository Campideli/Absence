import 'dart:io';

class ServerConfig {

  const ServerConfig({
    required this.port,
    required this.host,
    required this.firebaseProjectId,
    required this.firebasePrivateKey,
    required this.firebaseClientEmail,
    required this.environment,
    required this.pdfServiceUrl,
    this.enableCors = true,
    this.allowedOrigins = const ['*'],
  });

  factory ServerConfig.fromEnvironment([Map<String, String>? envVars]) {
    final env = envVars ?? Platform.environment;
    
    // Parse allowed origins and clean them up
    final origins = env['ALLOWED_ORIGINS']?.split(',')
        .map((origin) => origin.trim())
        .where((origin) => origin.isNotEmpty)
        .toList() ?? ['*'];
    
    final environment = env['ENVIRONMENT'] ?? 'development';
    final isProduction = environment == 'production';
    
    // SECURITY: Validar CORS em produção no construtor (fail fast)
    if (isProduction) {
      final hasWildcard = origins.contains('*');
      final hasLocalhost = origins.any((origin) => 
        origin.contains('localhost') || 
        origin.contains('127.0.0.1'));
      final hasNonHttps = origins.any((origin) => 
        origin != '*' && !origin.startsWith('https://'));
      
      if (hasWildcard) {
        throw Exception('SECURITY: Wildcard CORS não permitido em produção');
      }
      if (hasLocalhost) {
        throw Exception('SECURITY: Localhost CORS não permitido em produção');
      }
      if (hasNonHttps) {
        throw Exception('SECURITY: Apenas HTTPS permitido em CORS de produção');
      }
      if (origins.isEmpty) {
        throw Exception('SECURITY: CORS deve ter pelo menos uma origem válida em produção');
      }
    }

    return ServerConfig(
      port: int.parse(env['PORT'] ?? '8080'),
      host: env['HOST'] ?? '0.0.0.0',
      firebaseProjectId: env['FIREBASE_PROJECT_ID'] ?? '',
      firebasePrivateKey: env['FIREBASE_PRIVATE_KEY'] ?? '',
      firebaseClientEmail: env['FIREBASE_CLIENT_EMAIL'] ?? '',
      environment: environment,
      pdfServiceUrl: env['PDF_SERVICE_URL'] ?? 'http://localhost:8000',
      enableCors: (env['ENABLE_CORS'] ?? 'true').toLowerCase() == 'true',
      allowedOrigins: origins,
    );
  }
  
  final int port;
  final String host;
  final String firebaseProjectId;
  final String firebasePrivateKey;
  final String firebaseClientEmail;
  final String environment;
  final String pdfServiceUrl;
  final bool enableCors;
  final List<String> allowedOrigins;

  bool get isDevelopment => environment == 'development';
  bool get isProduction => environment == 'production';
  
  /// Retorna as origens permitidas (já validadas no construtor)
  List<String> get safeAllowedOrigins => allowedOrigins;
}
