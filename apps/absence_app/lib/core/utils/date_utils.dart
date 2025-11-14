/// Utilitários para manipulação e formatação de datas
class AppDateUtils {
  const AppDateUtils._();

  /// Formata uma data no formato YYYY-MM-DD
  /// Usado para chaves em Maps de ausências por dia
  static String formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Verifica se uma data é hoje
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Verifica se duas datas são do mesmo dia
  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Gera uma lista de 6 dias da semana (Seg-Sáb) a partir de uma data
  static List<DateTime> generateWeekDays(DateTime startDate) {
    final currentWeekday = startDate.weekday;
    final monday = startDate.subtract(Duration(days: currentWeekday - 1));
    return List.generate(6, (index) => monday.add(Duration(days: index)));
  }

  /// Retorna a data do início da semana anterior
  static DateTime getPreviousWeek(DateTime currentWeekStart) {
    return currentWeekStart.subtract(const Duration(days: 7));
  }

  /// Retorna a data do início da próxima semana
  static DateTime getNextWeek(DateTime currentWeekStart) {
    return currentWeekStart.add(const Duration(days: 7));
  }

  /// Retorna o nome abreviado do dia da semana (3 letras)
  static String getDayName(DateTime date) {
    const weekDays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return weekDays[date.weekday - 1];
  }

  /// Retorna o nome completo do dia da semana
  static String getFullDayName(DateTime date) {
    const weekDays = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo'
    ];
    return weekDays[date.weekday - 1];
  }

  /// Retorna o nome do mês
  static String getMonthName(DateTime date) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro'
    ];
    return months[date.month - 1];
  }

  /// Formata data completa: "Seg, 11 de Outubro"
  static String formatFullDate(DateTime date) {
    return '${getDayName(date)}, ${date.day} de ${getMonthName(date)}';
  }
}
