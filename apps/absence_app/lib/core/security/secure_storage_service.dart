import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static const SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    wOptions: WindowsOptions(),
    lOptions: LinuxOptions(),
    webOptions: WebOptions(
      dbName: 'AbsenceAppSecureStorage',
      publicKey: 'AbsenceApp_PublicKey',
    ),
  );

  const SecureStorageService._internal();

  /// Armazena dados sensíveis de forma segura
  Future<void> storeSecure(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      // Fallback para SharedPreferences em caso de erro (menos seguro)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    }
  }

  /// Recupera dados sensíveis armazenados de forma segura
  Future<String?> getSecure(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      if (value != null) {
        return value;
      }
      
      // Tentar fallback para SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final fallbackValue = prefs.getString(key);
      
      if (fallbackValue != null) {
        // Migrar para armazenamento seguro
        await storeSecure(key, fallbackValue);
        await prefs.remove(key); // Remover da localização menos segura
        return fallbackValue;
      }
      
      return null;
    } catch (e) {
      // Fallback para SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
  }

  /// Remove dados sensíveis armazenados
  Future<void> deleteSecure(String key) async {
    try {
      await _secureStorage.delete(key: key);
      
      // Também remover de SharedPreferences se existir
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      // Falha silenciosa
    }
  }

  /// Remove todos os dados armazenados de forma segura
  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
      
      // Também limpar SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = [
        'user_id',
        'user_email', 
        'user_name',
        'firebase_token',
        'last_login',
      ];
      
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
    } catch (e) {
      // Falha silenciosa
    }
  }

  /// Verifica se existe um valor para a chave especificada
  Future<bool> containsKey(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      if (value != null) {
        return true;
      }
      
      // Verificar também em SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    } catch (e) {
      return false;
    }
  }

  /// Migra dados existentes do SharedPreferences para armazenamento seguro
  Future<void> migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keysToMigrate = [
        'user_id',
        'user_email',
        'user_name',
        'firebase_token',
      ];

      for (final key in keysToMigrate) {
        final value = prefs.getString(key);
        if (value != null) {
          await storeSecure(key, value);
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // Falha silenciosa na migração
    }
  }

  /// Armazena dados do usuário de forma segura
  Future<void> storeUserData({
    required String userId,
    required String email,
    required String name,
    String? firebaseToken,
  }) async {
    await storeSecure('user_id', userId);
    await storeSecure('user_email', email);
    await storeSecure('user_name', name);
    
    if (firebaseToken != null) {
      await storeSecure('firebase_token', firebaseToken);
    }
    
    await storeSecure('last_login', DateTime.now().toIso8601String());
  }

  /// Recupera dados do usuário armazenados de forma segura
  Future<Map<String, String?>> getUserData() async {
    return {
      'user_id': await getSecure('user_id'),
      'user_email': await getSecure('user_email'),
      'user_name': await getSecure('user_name'),
      'firebase_token': await getSecure('firebase_token'),
      'last_login': await getSecure('last_login'),
    };
  }

  /// Verifica se existe dados de usuário armazenados
  Future<bool> hasUserData() async {
    final userId = await getSecure('user_id');
    return userId != null && userId.isNotEmpty;
  }
}