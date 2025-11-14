import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  const EnvConfig._();
  
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }
  
  /// Obtém um valor do arquivo .env
  static String? getValue(String key) {
    return dotenv.env[key];
  }
  
  // ==================== API CONFIGURATION ====================
  
  static String get apiBaseUrl => 
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';
      
  static String get appEnvironment => 
      dotenv.env['ENVIRONMENT'] ?? 'development';
  
  // ==================== FIREBASE WEB ====================
  
  static String get firebaseWebApiKey => 
      dotenv.env['FIREBASE_WEB_API_KEY'] ?? '';
      
  static String get firebaseWebAppId => 
      dotenv.env['FIREBASE_WEB_APP_ID'] ?? '';
      
  static String get firebaseWebMessagingSenderId => 
      dotenv.env['FIREBASE_WEB_MESSAGING_SENDER_ID'] ?? '';
      
  static String get firebaseWebProjectId => 
      dotenv.env['FIREBASE_WEB_PROJECT_ID'] ?? '';
      
  static String get firebaseWebAuthDomain => 
      dotenv.env['FIREBASE_WEB_AUTH_DOMAIN'] ?? '';
      
  static String get firebaseWebStorageBucket => 
      dotenv.env['FIREBASE_WEB_STORAGE_BUCKET'] ?? '';
      
  static String get firebaseWebMeasurementId => 
      dotenv.env['FIREBASE_WEB_MEASUREMENT_ID'] ?? '';
  
  // ==================== FIREBASE ANDROID ====================
  
  static String get firebaseAndroidApiKey => 
      dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '';
      
  static String get firebaseAndroidAppId => 
      dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '';
      
  static String get firebaseAndroidMessagingSenderId => 
      dotenv.env['FIREBASE_ANDROID_MESSAGING_SENDER_ID'] ?? '';
      
  static String get firebaseAndroidProjectId => 
      dotenv.env['FIREBASE_ANDROID_PROJECT_ID'] ?? '';
      
  static String get firebaseAndroidStorageBucket => 
      dotenv.env['FIREBASE_ANDROID_STORAGE_BUCKET'] ?? '';
  
  // ==================== GOOGLE SIGN-IN ====================
  
  static String get googleWebClientId => 
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
  
  // ==================== CONFIGURAÇÕES GERAIS ====================
  
  static String get environment => 
      dotenv.env['ENVIRONMENT'] ?? 'production';
      
  static bool get debugMode => 
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
  
  // ==================== VALIDAÇÕES ====================
  
  static bool get isConfigured {
    return firebaseWebApiKey.isNotEmpty &&
           firebaseWebAppId.isNotEmpty &&
           firebaseAndroidApiKey.isNotEmpty &&
           firebaseAndroidAppId.isNotEmpty &&
           googleWebClientId.isNotEmpty;
  }
  
  static List<String> get missingVariables {
    final missing = <String>[];
    
    if (firebaseWebApiKey.isEmpty) missing.add('FIREBASE_WEB_API_KEY');
    if (firebaseWebAppId.isEmpty) missing.add('FIREBASE_WEB_APP_ID');
    if (firebaseAndroidApiKey.isEmpty) missing.add('FIREBASE_ANDROID_API_KEY');
    if (firebaseAndroidAppId.isEmpty) missing.add('FIREBASE_ANDROID_APP_ID');
    if (googleWebClientId.isEmpty) missing.add('GOOGLE_WEB_CLIENT_ID');
    
    return missing;
  }
}
