import 'dart:io';

import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('FirebaseService');

class FirebaseService {
  static FirebaseAdminApp? _app;
  static Firestore? _firestore;
  
  static Future<void> initialize([Map<String, String>? envVars]) async {
    if (_app != null) return; // Já inicializado
    
    try {
      // Ler variáveis de ambiente
      final env = envVars ?? Platform.environment;
      final projectId = env['FIREBASE_PROJECT_ID'];
      final privateKey = env['FIREBASE_PRIVATE_KEY'];
      final clientEmail = env['FIREBASE_CLIENT_EMAIL'];
      
      if (projectId == null || privateKey == null || clientEmail == null) {
        throw Exception('Credenciais Firebase incompletas nas variáveis de ambiente');
      }
      
      final credential = Credential.fromServiceAccountParams(
        clientId: 'client-id-placeholder', // Não é usado para autenticação real
        privateKey: privateKey.replaceAll('\\n', '\n'),
        email: clientEmail,
      );
      
      // Inicializar Firebase Admin
      _app = FirebaseAdminApp.initializeApp(projectId, credential);
      _firestore = Firestore(_app!);

      _logger.info('Firebase Admin SDK inicializado com sucesso!');
      
    } catch (e) {
      _logger.severe('❌ Erro ao inicializar Firebase: $e');
      rethrow;
    }
  }
  
  static Firestore get firestore {
    if (_firestore == null) {
      throw Exception('Firebase não foi inicializado. Chame FirebaseService.initialize() primeiro.');
    }
    return _firestore!;
  }
  
  static FirebaseAdminApp get app {
    if (_app == null) {
      throw Exception('Firebase não foi inicializado. Chame FirebaseService.initialize() primeiro.');
    }
    return _app!;
  }
  
  /// Testa a conexão com Firebase
  static Future<bool> testConnection() async {
    try {
      await initialize();
      
      // Fazer um teste simples
      final testDoc = firestore.collection('_test').doc('connection_test');
      await testDoc.set({
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'connected',
      });
      
      final doc = await testDoc.get();
      final success = doc.exists;
      
      if (success) {
        await testDoc.delete(); // Limpar teste
      }
      
      return success;
    } catch (e) {
      _logger.info('❌ Erro no teste de conexão Firebase: $e');
      return false;
    }
  }
}
