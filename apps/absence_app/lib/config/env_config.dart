/// Environment configuration using compile-time constants.
/// Values are injected via --dart-define during build.
class EnvConfig {
  const EnvConfig._();
  
  // ==================== API CONFIGURATION ====================
  
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
  
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  
  // ==================== FIREBASE WEB ====================
  
  static const String firebaseWebApiKey = String.fromEnvironment(
    'FIREBASE_WEB_API_KEY',
    defaultValue: '',
  );
      
  static const String firebaseWebAppId = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
    defaultValue: '',
  );
      
  static const String firebaseWebMessagingSenderId = String.fromEnvironment(
    'FIREBASE_WEB_MESSAGING_SENDER_ID',
    defaultValue: '',
  );
      
  static const String firebaseWebProjectId = String.fromEnvironment(
    'FIREBASE_WEB_PROJECT_ID',
    defaultValue: '',
  );
      
  static const String firebaseWebAuthDomain = String.fromEnvironment(
    'FIREBASE_WEB_AUTH_DOMAIN',
    defaultValue: '',
  );
      
  static const String firebaseWebStorageBucket = String.fromEnvironment(
    'FIREBASE_WEB_STORAGE_BUCKET',
    defaultValue: '',
  );
      
  static const String firebaseWebMeasurementId = String.fromEnvironment(
    'FIREBASE_WEB_MEASUREMENT_ID',
    defaultValue: '',
  );
  
  // ==================== FIREBASE ANDROID ====================
  
  static const String firebaseAndroidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
    defaultValue: '',
  );
      
  static const String firebaseAndroidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
    defaultValue: '',
  );
      
  static const String firebaseAndroidMessagingSenderId = String.fromEnvironment(
    'FIREBASE_ANDROID_MESSAGING_SENDER_ID',
    defaultValue: '',
  );
      
  static const String firebaseAndroidProjectId = String.fromEnvironment(
    'FIREBASE_ANDROID_PROJECT_ID',
    defaultValue: '',
  );
      
  static const String firebaseAndroidStorageBucket = String.fromEnvironment(
    'FIREBASE_ANDROID_STORAGE_BUCKET',
    defaultValue: '',
  );
  
  // ==================== GOOGLE SIGN-IN ====================
  
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );
  
  // ==================== CONFIGURATION VALIDATION ====================
  
  static bool get debugMode => environment == 'development';
  
  static bool get isConfigured {
    return missingVariables.isEmpty;
  }
  
  static List<String> get missingVariables {
    final missing = <String>[];
    
    // Validar variáveis obrigatórias de Firebase Web
    if (firebaseWebApiKey.isEmpty) missing.add('FIREBASE_WEB_API_KEY');
    if (firebaseWebAppId.isEmpty) missing.add('FIREBASE_WEB_APP_ID');
    if (firebaseWebProjectId.isEmpty) missing.add('FIREBASE_WEB_PROJECT_ID');
    
    // Validar Google Sign-In
    if (googleWebClientId.isEmpty) missing.add('GOOGLE_WEB_CLIENT_ID');
    
    return missing;
  }
}
