import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/auth_service.dart';
import '../../../../core/security/security_service.dart';

class AuthProvider extends ChangeNotifier {

  /// Altera a senha do usuário autenticado
  Future<void> changePassword(String newPassword) async {
    try {
      _setLoading(true);
      _clearError();
      await _authService.changePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e));
      rethrow;
    } catch (e) {
      _setError(_getCleanErrorMessage(e.toString()));
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  bool _isGoogleSignInLoading = false;
  bool _isEmailSignInLoading = false;
  bool _isRegisterLoading = false;
  bool _isPasswordResetLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isGoogleSignInLoading => _isGoogleSignInLoading;
  bool get isEmailSignInLoading => _isEmailSignInLoading;
  bool get isRegisterLoading => _isRegisterLoading;
  bool get isPasswordResetLoading => _isPasswordResetLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _user = _authService.currentUser;
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setEmailSignInLoading(true);
      _clearError();
      
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e));
    } catch (e) {
      _setError(_getCleanErrorMessage(e.toString()));
    } finally {
      _setEmailSignInLoading(false);
    }
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _setRegisterLoading(true);
      _clearError();
      
      await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e));
    } catch (e) {
      _setError(_getCleanErrorMessage(e.toString()));
    } finally {
      _setRegisterLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _setGoogleSignInLoading(true);
      _clearError();
      
      await _authService.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e));
    } catch (e) {
      _setError(_getCleanErrorMessage(e.toString()));
    } finally {
      _setGoogleSignInLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.signOut();
    } catch (e) {
      _setError('Erro ao fazer logout: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      _setPasswordResetLoading(true);
      _clearError();
      
      await _authService.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e));
    } catch (e) {
      _setError(_getCleanErrorMessage(e.toString()));
    } finally {
      _setPasswordResetLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setGoogleSignInLoading(bool loading) {
    _isGoogleSignInLoading = loading;
    notifyListeners();
  }

  void _setEmailSignInLoading(bool loading) {
    _isEmailSignInLoading = loading;
    notifyListeners();
  }

  void _setRegisterLoading(bool loading) {
    _isRegisterLoading = loading;
    notifyListeners();
  }

  void _setPasswordResetLoading(bool loading) {
    _isPasswordResetLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  String _getErrorMessage(FirebaseAuthException e) {
    // Usar mensagens de erro seguras que não vazam informações
    return SecurityService.getSecureErrorMessage(e.code);
  }

  String _getCleanErrorMessage(String errorString) {
    // Remove prefixos desnecessários das exceptions
    String cleanMessage = errorString;
    
    // Remove "Exception: " do início
    if (cleanMessage.startsWith('Exception: ')) {
      cleanMessage = cleanMessage.substring(11);
    }
    
    // Remove "Error: " do início  
    if (cleanMessage.startsWith('Error: ')) {
      cleanMessage = cleanMessage.substring(7);
    }
    
    // Remove outros prefixos comuns
    if (cleanMessage.startsWith('Erro inesperado: ')) {
      cleanMessage = cleanMessage.substring(18);
    }
    
    // Se a mensagem já está limpa (sem prefixos), usar diretamente
    return cleanMessage;
  }
}
