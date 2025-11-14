import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:absence_app/config/app_config.dart';
import 'package:absence_app/core/security/secure_storage_service.dart';

class AuthService {

  /// Altera a senha do usuário autenticado de forma segura
  Future<void> changePassword(String newPassword) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-logged-in',
        message: 'Usuário não autenticado.'
      );
    }
    await user.updatePassword(newPassword);
    await _saveUserLocally(user);
  }
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final SecureStorageService _secureStorage = SecureStorageService();

  AuthService._internal() {
    _initializeGoogleSignIn();
    _migrateExistingData();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      final clientId = AppConfig.googleWebClientId;
      if (clientId.isEmpty) {
        throw Exception('GOOGLE_WEB_CLIENT_ID não configurado no .env');
      }
      
      // Apenas inicializar no mobile - na web não é necessário
      if (!kIsWeb) {
        await _googleSignIn.initialize(
          clientId: clientId,
        );
      }
    } catch (e) {
      throw Exception('Erro ao inicializar Google Sign-In: ${e.toString()}');
    }
  }

  /// Migra dados existentes do SharedPreferences para armazenamento seguro
  Future<void> _migrateExistingData() async {
    try {
      await _secureStorage.migrateFromSharedPreferences();
    } catch (e) {
      // Falha silenciosa na migração
    }
  }

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        await _saveUserLocally(credential.user!);
      }
      
      return credential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Erro inesperado: ${e.toString()}');
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null && displayName != null) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
      }

      if (credential.user != null) {
        await _saveUserLocally(credential.user!);
      }

      return credential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Erro inesperado: ${e.toString()}');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final clientId = AppConfig.googleWebClientId;
      if (clientId.isEmpty) {
        throw Exception(AppConfig.googleConfigNotSetMessage);
      }

      UserCredential? userCredential;

      if (kIsWeb) {
        // Na web, usar Firebase Auth com popup
        final googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({
          'client_id': clientId,
          'prompt': 'select_account',
        });
        
        userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        // No mobile, usar Google Sign-In SDK
        await _googleSignIn.signOut();
        final account = await _googleSignIn.authenticate();
        userCredential = await _handleGoogleSignInAccount(account);
      }
      
      if (userCredential?.user != null) {
        await _saveUserLocally(userCredential!.user!);
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' || 
          e.code == 'cancelled-popup-request' ||
          e.code == 'web-context-cancelled') {
        throw Exception(AppConfig.userCancelledMessage);
      }
      throw Exception('Erro de autenticação: ${e.message ?? e.code}');
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      
      if (errorString.contains('popup') || 
          errorString.contains('cancelled') ||
          errorString.contains('aborted')) {
        throw Exception(AppConfig.userCancelledMessage);
      }
      
      rethrow;
    }
  }

  /// Processa uma conta do Google Sign-In e autentica com Firebase
  Future<UserCredential?> _handleGoogleSignInAccount(GoogleSignInAccount account) async {
    final GoogleSignInAuthentication googleAuth = account.authentication;

    if (googleAuth.idToken == null) {
      throw Exception('Erro ao obter token de autenticação do Google');
    }

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    
    if (userCredential.user != null) {
      await _saveUserLocally(userCredential.user!);
    }
    
    return userCredential;
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
      await _clearUserLocally();
    } catch (e) {
      throw Exception('Erro ao fazer logout: ${e.toString()}');
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Erro inesperado: ${e.toString()}');
    }
  }

  Future<void> _saveUserLocally(User user) async {
    final token = await user.getIdToken();
    await _secureStorage.storeUserData(
      userId: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? '',
      firebaseToken: token,
    );
  }

  Future<void> _clearUserLocally() async {
    await _secureStorage.clearAll();
  }

  Future<bool> checkLocalAuth() async {
    final hasUserData = await _secureStorage.hasUserData();
    return hasUserData && currentUser != null;
  }
}
