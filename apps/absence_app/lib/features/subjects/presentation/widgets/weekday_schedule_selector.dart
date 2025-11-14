import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/design_constants.dart';

class WeekdayScheduleSelector extends StatelessWidget {
  final String weekdayName;
  final List<TimeOfDay> selectedTimes;
  final Function(List<TimeOfDay>) onTimesChanged;
  final int maxTimes;

  const WeekdayScheduleSelector({
    super.key,
    required this.weekdayName,
    required this.selectedTimes,
    required this.onTimesChanged,
    this.maxTimes = 3,
  });

  Future<void> _selectTime(BuildContext context) async {
    final initialTime = selectedTimes.isNotEmpty 
        ? selectedTimes.first 
        : const TimeOfDay(hour: 19, minute: 30);
    final colorScheme = Theme.of(context).colorScheme;
    
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      initialEntryMode: TimePickerEntryMode.inputOnly,
      helpText: 'Selecionar horário',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      hourLabelText: 'Hora',
      minuteLabelText: 'Minuto',
      errorInvalidText: 'Horário inválido',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                backgroundColor: colorScheme.surface,
                hourMinuteTextColor: Colors.white,
                hourMinuteColor: colorScheme.surfaceContainerHighest,
                confirmButtonStyle: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.white),
                  foregroundColor: WidgetStateProperty.all(Colors.black),
                  elevation: WidgetStateProperty.all(0),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  overlayColor: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.pressed)) {
                        return Colors.black.withValues(alpha: 0.15);
                      }
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.black.withValues(alpha: 0.08);
                      }
                      return null;
                    },
                  ),
                ),
                cancelButtonStyle: ButtonStyle(
                  foregroundColor: WidgetStateProperty.all(
                    Colors.white.withValues(alpha: 0.7),
                  ),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  overlayColor: WidgetStateProperty.all(
                    Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                helpTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignConstants.radiusLg),
                ),
              ),
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: Colors.white,
                selectionColor: Colors.white.withValues(alpha: 0.3),
                selectionHandleColor: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      // Verificar se o horário já existe
      final isDuplicate = selectedTimes.any((time) => 
        time.hour == picked.hour && time.minute == picked.minute
      );
      
      if (isDuplicate) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Este horário já foi adicionado para ${weekdayName.toLowerCase()}',
              ),
              backgroundColor: const Color(0xFFD32F2F),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
        return;
      }
      
      final newTimes = [...selectedTimes, picked];
      onTimesChanged(newTimes);
    }
  }

  void _removeTime(int index) {
    final newTimes = [...selectedTimes];
    newTimes.removeAt(index);
    onTimesChanged(newTimes);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: DesignConstants.sm),
      padding: const EdgeInsets.all(DesignConstants.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignConstants.radiusSm),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nome do dia da semana
          Text(
            weekdayName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: DesignConstants.sm),
          
          // Horários e botões
          selectedTimes.isEmpty
              ? OutlinedButton.icon(
                  onPressed: () => _selectTime(context),
                  icon: Icon(
                    Icons.access_time,
                    size: 18,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  label: Text(
                    'Selecionar',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignConstants.md,
                      vertical: DesignConstants.sm,
                    ),
                    side: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignConstants.radiusSm),
                    ),
                  ).copyWith(
                    overlayColor: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.pressed)) {
                          return Colors.white.withValues(alpha: 0.15);
                        }
                        if (states.contains(WidgetState.hovered)) {
                          return Colors.white.withValues(alpha: 0.08);
                        }
                        return null;
                      },
                    ),
                  ),
                )
              : Wrap(
                  spacing: DesignConstants.xs,
                  runSpacing: DesignConstants.xs,
                  children: [
                    // Horários existentes com botão de remover
                    ...List.generate(
                      selectedTimes.length,
                      (index) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignConstants.sm,
                          vertical: DesignConstants.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(DesignConstants.radiusSm),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(selectedTimes[index]),
                              style: AppTextStyles.badgeText(context).copyWith(color: Colors.white),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _removeTime(index),
                              borderRadius: BorderRadius.circular(12),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Botão de adicionar (se não atingiu o limite)
                    if (selectedTimes.length < maxTimes)
                      InkWell(
                        onTap: () => _selectTime(context),
                        borderRadius: BorderRadius.circular(DesignConstants.radiusSm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignConstants.sm,
                            vertical: DesignConstants.xs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(DesignConstants.radiusSm),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
        ],
      ),
    );
  }
}
