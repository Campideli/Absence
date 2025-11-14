import 'package:flutter/material.dart';



import 'package:provider/provider.dart';
import '../../../subjects/presentation/providers/subject_provider.dart';
import '../../../../core/utils/date_utils.dart';
import 'day_section.dart';
import 'schedule_card.dart';



class WeeklyScheduleWidget extends StatelessWidget {
  const WeeklyScheduleWidget({super.key});


  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectProvider>().subjects;

    // Agrupa aulas por dia da semana (1=Segunda, ..., 6=Sábado)
    final Map<int, List<Map<String, String>>> weekMap = {};
    for (final subject in subjects) {
      for (final sched in subject.classSchedules) {
        weekMap.putIfAbsent(sched.weekday, () => []).add({
          'subjectName': subject.name,
          'startTime': sched.startTime,
        });
      }
    }

    for (final entries in weekMap.values) {
      entries.sort((a, b) => a['startTime']!.compareTo(b['startTime']!));
    }

    final List<int> weekOrder = [1, 2, 3, 4, 5, 6, 7];
    final List<int> sortedWeekdays = [
      ...weekOrder.where((d) => weekMap.containsKey(d)),
    ];

    if (sortedWeekdays.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedWeekdays.length,
          separatorBuilder: (_, __) => const SizedBox(height: 20),
          itemBuilder: (context, idx) {
            final weekday = sortedWeekdays[idx];
            final entries = weekMap[weekday]!;
            final fakeDate = DateTime(2020, 1, 6 + (weekday - 1));
            final weekdayLabel = AppDateUtils.getFullDayName(fakeDate);
            return DaySection(
              weekdayLabel: weekdayLabel,
              entries: entries
                  .map((e) => ScheduleCard(
                        subjectName: e['subjectName']!,
                        startTime: e['startTime']!,
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
