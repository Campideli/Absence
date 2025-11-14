import 'package:flutter/material.dart';
import '../../../../core/constants/design_constants.dart';
import '../../../absences/presentation/widgets/day_chip.dart';

class WeekdaySelector extends StatelessWidget {
  final Set<int> selectedWeekdays;
  final Function(int) onWeekdayToggle;

  const WeekdaySelector({
    super.key,
    required this.selectedWeekdays,
    required this.onWeekdayToggle,
  });

  // Gera uma data fictícia para cada dia da semana (apenas para exibição)
  DateTime _getDateForWeekday(int weekday) {
    // Pega segunda-feira da semana atual
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    // Retorna o dia correspondente (weekday 1 = segunda, 6 = sábado)
    return monday.add(Duration(days: weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primeira linha: Seg, Ter, Qua
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int weekday = 1; weekday <= 3; weekday++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: weekday < 3 ? DesignConstants.xs : 0,
                  ),
                  child: DayChip(
                    date: _getDateForWeekday(weekday),
                    isSelected: selectedWeekdays.contains(weekday),
                    showDayNumber: false,   // Não mostra número do dia
                    showTodayLabel: false,  // Não mostra "Hoje"
                    onSelected: (_) => onWeekdayToggle(weekday),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: DesignConstants.xs),
        // Segunda linha: Qui, Sex, Sáb
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int weekday = 4; weekday <= 6; weekday++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: weekday < 6 ? DesignConstants.xs : 0,
                  ),
                  child: DayChip(
                    date: _getDateForWeekday(weekday),
                    isSelected: selectedWeekdays.contains(weekday),
                    showDayNumber: false,   // Não mostra número do dia
                    showTodayLabel: false,  // Não mostra "Hoje"
                    onSelected: (_) => onWeekdayToggle(weekday),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
