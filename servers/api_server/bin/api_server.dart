import 'dart:io';
import 'package:api_server/api_server.dart';
import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';

/// Loads environment variables from .env file if it exists (development)
/// or uses system environment variables (production)
Map<String, String> _loadEnvironment() {
  final envFile = File('.env');
  
  // If .env exists, load it (development mode)
  if (envFile.existsSync()) {
    final dotEnv = DotEnv(includePlatformEnvironment: true)..load();
    // Merge Platform.environment with .env, giving priority to .env
    return {
      ...Platform.environment,
      for (var key in [
        'ENVIRONMENT',
        'PORT',
        'HOST',
        'LOG_LEVEL',
        'ENABLE_CORS',
        'ALLOWED_ORIGINS',
        'FIREBASE_PROJECT_ID',
        'FIREBASE_PRIVATE_KEY',
        'FIREBASE_CLIENT_EMAIL',
        'FIREBASE_WEB_API_KEY',
        'PDF_SERVICE_URL',
      ])
        if (dotEnv[key] != null) key: dotEnv[key]!,
    };
  }
  
  // Production: use only system environment variables
  return Platform.environment;
}

void main() async {
  try {
    // Load environment variables
    final env = _loadEnvironment();
    
    // Initialize logging service
    await LoggingService.initialize();
    
    final logger = Logger('APIServer');
    logger.info('Iniciando servidor API...');
    
    // Initialize configuration from environment variables
    final config = ServerConfig.fromEnvironment(env);
    
    // Initialize Firebase and Auth
    await FirebaseService.initialize(env);
    await AuthService.initialize(env);
    
    // Create and start server
    final server = ApiServer(config);
    await server.start();
    
    logger.info('Server started successfully on port ${config.port}');
    
    // Handle graceful shutdown
    ProcessSignal.sigint.watch().listen((signal) async {
      logger.info('Received SIGINT. Shutting down gracefully...');
      await server.stop();
      exit(0);
    });
    
  } catch (e, stackTrace) {
    final errorLogger = Logger('APIServer');
    errorLogger.severe('Failed to start server: $e', e, stackTrace);
    exit(1);
  }
}
