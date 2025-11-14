import 'package:flutter/material.dart';
import 'day_chip.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../../core/constants/design_constants.dart';

/// Navegador de semana com setas laterais e chips de dias
class WeekNavigator extends StatelessWidget {
  /// Dias da semana permitidos (1=Segunda, ..., 7=Domingo)
  final Set<int>? allowedWeekdays;
  final List<DateTime> weekDays;
  final DateTime? selectedDate; // Para seleção única (compatibilidade)
  final Set<DateTime>? selectedDates; // Para seleção múltipla
  final Map<String, int> absencesPerDay;
  final bool isLoading;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final ValueChanged<DateTime> onDaySelected;
  final bool enableOnlyWithAbsences;
  final bool multipleSelection; // Flag para habilitar seleção múltipla
  final bool showAbsenceBorder; // Novo: controla se mostra borda vermelha de faltas

  const WeekNavigator({
    super.key,
    required this.weekDays,
    this.selectedDate,
    this.selectedDates,
    required this.absencesPerDay,
    required this.isLoading,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onDaySelected,
    this.enableOnlyWithAbsences = false,
    this.multipleSelection = false,
    this.showAbsenceBorder = true, // Por padrão mostra (compatibilidade)
  this.allowedWeekdays,
  }) : assert(
          (multipleSelection && selectedDates != null) || 
          (!multipleSelection && selectedDate != null),
          'Use selectedDates para seleção múltipla ou selectedDate para seleção única',
        );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dia da Semana',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: DesignConstants.sm),
        Row(
          children: [
            IconButton(
              onPressed: onPreviousWeek,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Semana anterior',
              iconSize: DesignConstants.iconSizeMedium,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.onSurface,
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return Center(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: weekDays.map((day) {
                              final dateKey = app_date_utils.AppDateUtils.formatDateKey(day);
                              final hasAbsences = (absencesPerDay[dateKey] ?? 0) > 0;
                              final weekday = day.weekday;
                              final isAllowed = allowedWeekdays == null || allowedWeekdays!.contains(weekday);
                              final isPastOrToday = !day.isAfter(DateTime.now());
                              // Verificar se está selecionado (múltipla ou única)
                              final isSelected = multipleSelection
                                  ? (selectedDates?.any((d) => app_date_utils.AppDateUtils.isSameDay(d, day)) ?? false)
                                  : app_date_utils.AppDateUtils.isSameDay(selectedDate, day);

                              return DayChip(
                                date: day,
                                isSelected: isSelected,
                                hasAbsences: showAbsenceBorder && hasAbsences, // Só mostra se habilitado
                                isToday: app_date_utils.AppDateUtils.isToday(day),
                                isEnabled: isAllowed && isPastOrToday && (enableOnlyWithAbsences ? hasAbsences : true),
                                onSelected: (_) => onDaySelected(day),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(width: 2),
            IconButton(
              onPressed: onNextWeek,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Próxima semana',
              iconSize: DesignConstants.iconSizeMedium,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }
}
