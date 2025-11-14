import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'env_config.dart';

class AppConfig {
  const AppConfig._();

  static FirebaseOptions get firebaseOptions => DefaultFirebaseOptions.currentPlatform;
  
  static String get projectId => kIsWeb 
      ? EnvConfig.firebaseWebProjectId 
      : EnvConfig.firebaseAndroidProjectId;
  
  static String get apiKey => kIsWeb 
      ? EnvConfig.firebaseWebApiKey 
      : EnvConfig.firebaseAndroidApiKey;
  
  static String get appId => kIsWeb 
      ? EnvConfig.firebaseWebAppId 
      : EnvConfig.firebaseAndroidAppId;
  
  static String? get authDomain => kIsWeb ? EnvConfig.firebaseWebAuthDomain : null;
  
  static String? get storageBucket => kIsWeb 
      ? EnvConfig.firebaseWebStorageBucket 
      : EnvConfig.firebaseAndroidStorageBucket;

  static String get googleWebClientId => EnvConfig.googleWebClientId;
  
  static const String googleConfigNotSetMessage = 
      'Google Sign-In não está configurado para web. '
      'Verifique as variáveis de ambiente no arquivo .env';
      
  static const String userCancelledMessage = 'Login cancelado pelo usuário';

  static String get environment => EnvConfig.environment;
  static bool get debugMode => EnvConfig.debugMode;
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';

  static bool get isWeb => kIsWeb;
  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  
  static bool get isConfigured => EnvConfig.isConfigured;
  static List<String> get missingVariables => EnvConfig.missingVariables;
  
  static void validateConfiguration() {
    if (!isConfigured) {
      final missing = missingVariables.join(', ');
      throw Exception(
        'Configuração incompleta! Variáveis de ambiente faltando: $missing\n'
        'Verifique o arquivo .env e copie o .env.example se necessário.'
      );
    }
  }
}
