import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../subjects/presentation/providers/subject_provider.dart';
import '../../../../core/theme/theme_exports.dart';
import '../../../../shared/widgets/layout/spacings.dart';

/// Widget de prévia dos horários do dia atual para a dashboard

typedef GoToSchedulesCallback = void Function();

class TodaySchedulePreview extends StatelessWidget {
  final GoToSchedulesCallback? onGoToSchedules;
  const TodaySchedulePreview({super.key, this.onGoToSchedules});

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectProvider>().subjects;
    final today = DateTime.now().weekday; // 1=Segunda, ..., 7=Domingo
    final todayEntries = <_TodayScheduleEntry>[];
    for (final subject in subjects) {
      for (final sched in subject.classSchedules) {
        if (sched.weekday == today) {
          todayEntries.add(_TodayScheduleEntry(
            subjectName: subject.name,
            startTime: sched.startTime,
          ));
        }
      }
    }
    todayEntries.sort((a, b) => a.startTime.compareTo(b.startTime));

    final colorScheme = Theme.of(context).colorScheme;
    final hasSubjects = subjects.isNotEmpty;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onGoToSchedules,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Horário de hoje', style: AppTextStyles.sectionTitle(context)),
              const SmallSpacing(),
              if (!hasSubjects) ...[
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Nenhuma matéria cadastrada ainda.\nAdicione matérias para visualizar seus horários.',
                    style: AppTextStyles.bodyText(context).copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
              ] else ...[
                if (todayEntries.isEmpty)
                  SizedBox(
                    height: 56,
                    child: Center(
                      child: Text(
                        'Nenhuma aula hoje.',
                        style: AppTextStyles.bodyText(context).copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                if (todayEntries.isNotEmpty)
                  Column(
                    children: todayEntries.map((e) => _TodayScheduleRow(entry: e)).toList(),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayScheduleEntry {
  final String subjectName;
  final String startTime;
  _TodayScheduleEntry({required this.subjectName, required this.startTime});
}

class _TodayScheduleRow extends StatelessWidget {
  final _TodayScheduleEntry entry;
  const _TodayScheduleRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(entry.subjectName, style: AppTextStyles.bodyText(context))),
          Text(entry.startTime, style: AppTextStyles.bodyText(context).copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}
