import 'dart:io';
import 'package:api_server/api_server.dart';
import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';

void main() async {
  try {
    // Load environment variables first
    final env = DotEnv(includePlatformEnvironment: true)..load();
    
    // Initialize logging service
    await LoggingService.initialize();
    
    final logger = Logger('APIServer');
    logger.info('Iniciando servidor API...');
    
    // Initialize configuration
    final config = ServerConfig.fromEnvironment(env);
    
    // Initialize Firebase and Auth
    await FirebaseService.initialize();
    await AuthService.initialize();
    
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
