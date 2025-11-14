class SecurityService {
  const SecurityService._();

  /// Instância singleton
  static const SecurityService _instance = SecurityService._();
  factory SecurityService() => _instance;

  /// Sanitiza dados de entrada removendo caracteres perigosos
  Map<String, dynamic> sanitizeInput(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in data.entries) {
      if (entry.value is String) {
        // Remove scripts maliciosos e caracteres perigosos
        String sanitizedValue = entry.value
            .replaceAll(RegExp(r'<script[^>]*>.*?</script>'), '')
            .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
            .replaceAll(RegExp(r'on\w+\s*='), '')
            .trim();
        
        // Limita o tamanho das strings
        if (sanitizedValue.length > 1000) {
          sanitizedValue = sanitizedValue.substring(0, 1000);
        }
        
        sanitized[entry.key] = sanitizedValue;
      } else if (entry.value is Map<String, dynamic>) {
        sanitized[entry.key] = sanitizeInput(entry.value);
      } else if (entry.value is List) {
        sanitized[entry.key] = _sanitizeList(entry.value);
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    
    return sanitized;
  }

  /// Sanitiza listas recursivamente
  List<dynamic> _sanitizeList(List<dynamic> list) {
    return list.map((item) {
      if (item is String) {
        return item
            .replaceAll(RegExp(r'<script[^>]*>.*?</script>'), '')
            .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
            .replaceAll(RegExp(r'on\w+\s*='), '')
            .trim();
      } else if (item is Map<String, dynamic>) {
        return sanitizeInput(item);
      } else if (item is List) {
        return _sanitizeList(item);
      }
      return item;
    }).toList();
  }

  /// Valida se um email é válido
  bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  /// Valida se uma senha é forte
  bool isStrongPassword(String password) {
    // Pelo menos 8 caracteres, 1 maiúscula, 1 minúscula, 1 número
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }

  /// Retorna mensagens de erro amigáveis para códigos de erro do Firebase Auth
  static String getSecureErrorMessage(String errorCode) {
    switch (errorCode) {
      // Erros de email/senha
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-credential':
        return 'Credenciais inválidas.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'user-disabled':
        return 'Esta conta foi desabilitada.';
      case 'missing-email':
        return 'Email é obrigatório.';
      
      // Erros de criação de conta
      case 'email-already-in-use':
        return 'Este email já está em uso.';
      case 'weak-password':
        return 'A senha é muito fraca.';
      
      // Erros de rede
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      
      // Erros do Google Sign-In
      case 'account-exists-with-different-credential':
        return 'Já existe uma conta com este email.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      case 'invalid-verification-code':
        return 'Código de verificação inválido.';
      case 'invalid-verification-id':
        return 'ID de verificação inválido.';
      
      // Erro genérico
      default:
        return 'Ocorreu um erro. Tente novamente.';
    }
  }
}
