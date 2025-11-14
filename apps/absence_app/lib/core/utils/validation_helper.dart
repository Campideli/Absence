/// Validadores reutilizáveis para formulários
class ValidationHelper {
  const ValidationHelper._();

  // =====================
  // SUBJECT VALIDATION
  // =====================

  /// Valida o nome de uma matéria
  static String? validateSubjectName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nome é obrigatório';
    }
    if (value.trim().length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }
    if (value.trim().length > 50) {
      return 'Nome não pode exceder 50 caracteres';
    }
    return null;
  }

  /// Valida o número máximo de faltas
  static String? validateMaxAbsences(String? value) {
    if (value == null || value.isEmpty) {
      return 'Número de faltas é obrigatório';
    }
    final number = int.tryParse(value);
    if (number == null) {
      return 'Insira um número válido';
    }
    if (number <= 0) {
      return 'Deve ser maior que zero';
    }
    if (number > 100) {
      return 'Máximo de 100 faltas';
    }
    return null;
  }

  // =====================
  // ABSENCE VALIDATION
  // =====================

  /// Valida a quantidade de faltas a serem adicionadas
  static String? validateAbsenceQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quantidade é obrigatória';
    }
    final number = int.tryParse(value);
    if (number == null) {
      return 'Insira um número válido';
    }
    if (number <= 0) {
      return 'Deve ser maior que zero';
    }
    if (number > 20) {
      return 'Máximo de 20 faltas por registro';
    }
    return null;
  }

  /// Valida a razão/motivo da falta (opcional)
  static String? validateAbsenceReason(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // É opcional
    }
    if (value.trim().length > 200) {
      return 'Motivo não pode exceder 200 caracteres';
    }
    return null;
  }

  // =====================
  // COMMON VALIDATION
  // =====================

  /// Valida se um valor numérico está dentro de um range
  static String? validateNumberInRange(
    String? value, {
    required int min,
    required int max,
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Valor'} é obrigatório';
    }
    final number = int.tryParse(value);
    if (number == null) {
      return 'Insira um número válido';
    }
    if (number < min || number > max) {
      return '${fieldName ?? 'Valor'} deve estar entre $min e $max';
    }
    return null;
  }

  /// Valida se um texto tem um tamanho mínimo e máximo
  static String? validateTextLength(
    String? value, {
    required int min,
    required int max,
    String? fieldName,
    bool required = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return required ? '${fieldName ?? 'Campo'} é obrigatório' : null;
    }
    if (value.trim().length < min) {
      return '${fieldName ?? 'Campo'} deve ter pelo menos $min caracteres';
    }
    if (value.trim().length > max) {
      return '${fieldName ?? 'Campo'} não pode exceder $max caracteres';
    }
    return null;
  }
}
