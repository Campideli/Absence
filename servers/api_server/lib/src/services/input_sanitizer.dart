import 'package:logging/logging.dart';

final Logger _logger = Logger('InputSanitizer');

class InputSanitizer {
  /// Sanitiza string removendo HTML, scripts e caracteres Unicode perigosos
  static String sanitizeString(String input) {
    if (input.isEmpty) return input;
    
    var sanitized = input;
    
    // Remove tags HTML e scripts
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');
    sanitized = sanitized.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '');
    
    // Remove caracteres Unicode perigosos
    // - Zero-width characters (podem ocultar texto)
    sanitized = sanitized.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');
    // - Bidirectional text override (pode inverter texto)
    sanitized = sanitized.replaceAll(RegExp(r'[\u202A-\u202E]'), '');
    // - Control characters exceto newline/tab
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]'), '');
    
    // Remove múltiplos espaços consecutivos
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    
    // Trim
    sanitized = sanitized.trim();
    
    // Log se houve modificação significativa (possível ataque)
    if (sanitized != input && sanitized.length < input.length * 0.8) {
      _logger.warning('Input sanitizado removeu mais de 20% do conteúdo - possível tentativa de injeção');
    }
    
    return sanitized;
  }
  
  /// Valida tamanho de string
  static bool validateLength(String input, int maxLength, {int minLength = 1}) {
    final length = input.length;
    return length >= minLength && length <= maxLength;
  }
  
  /// Sanitiza e valida string combinado
  static String? sanitizeAndValidate(
    String? input, 
    int maxLength, {
    int minLength = 1,
    bool required = true,
  }) {
    if (input == null || input.isEmpty) {
      return required ? null : '';
    }
    
    final sanitized = sanitizeString(input);
    
    if (!validateLength(sanitized, maxLength, minLength: minLength)) {
      return null;
    }
    
    return sanitized;
  }
}
