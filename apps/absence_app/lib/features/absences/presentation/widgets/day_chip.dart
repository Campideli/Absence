import 'package:flutter/material.dart';
import '../../../../core/constants/design_constants.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;

/// Chip para exibir um dia da semana com estado selecionado e indicadores visuais
class DayChip extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool hasAbsences;
  final bool isToday;
  final bool isEnabled;
  final ValueChanged<bool>? onSelected;
  final bool showDayNumber; // Novo: controla se mostra o número do dia
  final bool showTodayLabel; // Novo: controla se mostra o label "Hoje"

  const DayChip({
    super.key,
    required this.date,
    required this.isSelected,
    this.hasAbsences = false,
    this.isToday = false,
    this.isEnabled = true,
    this.onSelected,
    this.showDayNumber = true,  // Por padrão mostra o número
    this.showTodayLabel = true, // Por padrão mostra "Hoje"
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: DesignConstants.dayChipWidth,
      height: DesignConstants.dayChipHeight,
      child: ChoiceChip(
        label: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                app_date_utils.AppDateUtils.getDayName(date),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : colorScheme.onSurface,
                ),
              ),
              if (showDayNumber) ...[
                const SizedBox(height: 2),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : colorScheme.onSurface,
                  ),
                ),
              ],
              if (isToday && showTodayLabel) ...[
                const SizedBox(height: 2),
                const Text(
                  'Hoje',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
        selected: isSelected,
        onSelected: isEnabled ? onSelected : null,
        selectedColor: isSelected 
            ? Colors.white.withValues(alpha: 0.03) // Fundo BRANCO translúcido quando selecionado
            : colorScheme.surfaceContainerHighest,
        backgroundColor: colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.all(4),
        labelPadding: EdgeInsets.zero,
        showCheckmark: false,
        disabledColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        side: BorderSide(
          color: hasAbsences
              ? colorScheme.error
              : (isSelected
                  ? Colors.white
                  : colorScheme.outline.withValues(alpha: 0.2)),
          width: 1,
        ),
        elevation: 0,
        shadowColor: null,
      ),
    );
  }
}
