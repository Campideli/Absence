/// Utilitário centralizado para validação e normalização de datas
/// 
/// SECURITY: Todas as datas devem ser:
/// 1. Normalizadas para UTC (evita inconsistências de timezone)
/// 2. Validadas contra ranges razoáveis (previne ataques de data manipulation)
/// 3. Alinhadas com regras do Firestore (consistência entre client/server)
class DateValidator {
  // Configuração de ranges (alinhado com Firestore rules)
  static final DateTime minAllowedDate = DateTime.utc(2020, 1, 1);
  static DateTime maxAllowedDate() =>
    DateTime.now().toUtc().add(const Duration(days: 1));
  
  /// Valida se uma data está dentro do range permitido
  /// 
  /// Returns: null se válida, mensagem de erro se inválida
  static String? validateDateRange(DateTime date) {
    final dateUtc = date.toUtc();
    final min = minAllowedDate;
    final max = maxAllowedDate();
    
    if (dateUtc.isBefore(min)) {
      return 'Date cannot be before ${_formatDate(min)}';
    }
    
    if (dateUtc.isAfter(max)) {
      return 'Date cannot be more than 1 day in the future';
    }
    
    return null;
  }
  
  /// Parse e normaliza string de data para UTC
  /// 
  /// Throws: FormatException se a string não for uma data válida
  static DateTime parseAndNormalize(String dateStr) {
    final parsed = DateTime.parse(dateStr);
    return normalizeToUtc(parsed);
  }
  
  /// Normaliza qualquer DateTime para UTC com hora zerada (apenas data)
  /// 
  /// SECURITY: Garante consistência - todas as datas armazenadas são UTC midnight
  static DateTime normalizeToUtc(DateTime date) {
    final utc = date.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }
  
  /// Valida e normaliza data em uma única operação
  /// 
  /// Returns: DateTime normalizado ou null se inválido
  /// errorMessage: mensagem de erro (se retornar null)
  static DateTime? validateAndNormalize(
    String dateStr, 
    {String? Function()? onError}
  ) {
    try {
      final normalized = parseAndNormalize(dateStr);
      final validationError = validateDateRange(normalized);
      
      if (validationError != null) {
        if (onError != null) {
          onError();
        }
        return null;
      }
      
      return normalized;
    } catch (e) {
      if (onError != null) {
        onError();
      }
      return null;
    }
  }
  
  /// Verifica se uma data é "hoje" (em UTC)
  static bool isToday(DateTime date) {
    final now = DateTime.now().toUtc();
    final dateUtc = date.toUtc();
    
    return dateUtc.year == now.year &&
           dateUtc.month == now.month &&
           dateUtc.day == now.day;
  }
  
  /// Verifica se uma data está no passado (antes de hoje)
  static bool isPast(DateTime date) {
    final today = normalizeToUtc(DateTime.now());
    final dateUtc = normalizeToUtc(date);
    
    return dateUtc.isBefore(today);
  }
  
  /// Verifica se uma data está no futuro (depois de hoje)
  static bool isFuture(DateTime date) {
    final today = normalizeToUtc(DateTime.now());
    final dateUtc = normalizeToUtc(date);
    
    return dateUtc.isAfter(today);
  }
  
  /// Formata data para mensagens de erro (formato ISO 8601 date-only)
  static String _formatDate(DateTime date) {
    final utc = date.toUtc();
    return '${utc.year}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')}';
  }
  
  /// Retorna a data de hoje normalizada (UTC midnight)
  static DateTime get today => normalizeToUtc(DateTime.now());
  
  /// Retorna a data de ontem normalizada (UTC midnight)
  static DateTime get yesterday => today.subtract(const Duration(days: 1));
  
  /// Retorna a data de amanhã normalizada (UTC midnight)
  static DateTime get tomorrow => today.add(const Duration(days: 1));
}
