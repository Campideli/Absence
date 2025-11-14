import 'package:flutter/material.dart';

class CalendarDayGrid extends StatelessWidget {
  final List<DateTime> days;
  final DateTime today;
  final DateTime? selectedDate;
  final Map<String, List<dynamic>> groupedByDay;
  final void Function(DateTime) onSelectDate;

  const CalendarDayGrid({
    super.key,
    required this.days,
    required this.today,
    required this.selectedDate,
    required this.groupedByDay,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 6,
      childAspectRatio: 1.2,
      physics: const NeverScrollableScrollPhysics(),
      children: days.map((d) {
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        final hasAbsence = groupedByDay.containsKey(key);
        final isSelected = selectedDate != null && DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day) == DateTime(d.year, d.month, d.day);
        final isFuture = DateTime(d.year, d.month, d.day).isAfter(DateTime(today.year, today.month, today.day));
        final enabled = !isFuture && hasAbsence;
        return Padding(
          padding: const EdgeInsets.all(4),
          child: Material(
            color: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: enabled ? () => onSelectDate(d) : null,
              hoverColor: colorScheme.primary.withAlpha((0.06 * 255).round()),
              splashColor: colorScheme.primary.withAlpha((0.12 * 255).round()),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary.withAlpha((0.12 * 255).round()) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: hasAbsence ? Border.all(color: Theme.of(context).colorScheme.error, width: 1.8) : Border.all(color: Colors.transparent),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${d.day}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: (hasAbsence || isSelected)
                              ? Colors.white
                              : (isFuture ? colorScheme.onSurface.withAlpha(120) : colorScheme.onSurface),
                          fontWeight: (hasAbsence || isSelected) ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
