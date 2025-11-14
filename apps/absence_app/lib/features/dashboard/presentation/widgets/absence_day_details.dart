import 'package:flutter/material.dart';
import '../../../../shared/models/absence_model.dart';

class AbsenceDayDetails extends StatelessWidget {
  final List<AbsenceModel> absences;
  final Map<String, String> subjectNameById;

  const AbsenceDayDetails({
    super.key,
    required this.absences,
    required this.subjectNameById,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    if (absences.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text('Nenhuma falta registrada neste dia.', style: textTheme.bodyMedium),
      );
    }

    // Agrupa as faltas por matéria, somando as quantidades e coletando motivos
    final Map<String, int> quantityBySubject = {};
    final Map<String, Set<String>> reasonsBySubject = {};
    for (final absence in absences) {
      quantityBySubject.update(
        absence.subjectId,
        (value) => value + (absence.quantity),
        ifAbsent: () => absence.quantity,
      );
      if (absence.reason != null && absence.reason!.trim().isNotEmpty) {
        reasonsBySubject.putIfAbsent(absence.subjectId, () => <String>{}).add(absence.reason!.trim());
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: quantityBySubject.entries.map((entry) {
        final subjectId = entry.key;
        final totalQuantity = entry.value;
        final subjectName = subjectNameById[subjectId] ?? subjectId;
        final reasons = reasonsBySubject[subjectId]?.toList() ?? [];
        final limitedReasons = reasons.take(5).map((r) => r.length > 20 ? r.substring(0, 20) : r).toList();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subjectName, style: textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Quantidade: $totalQuantity', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha(200))),
              if (limitedReasons.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Motivo: ${limitedReasons.join(", ")}',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha(200)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
