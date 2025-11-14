import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
import 'calendar_header.dart';
import 'calendar_day_grid.dart';
import 'absence_day_details.dart';
import '../../../../shared/models/absence_model.dart';
import '../../../subjects/presentation/providers/subject_provider.dart';
import '../../../../core/theme/theme_exports.dart';

class HomeMonthlyAbsenceCalendarWidget extends StatefulWidget {
  final List<AbsenceModel> absences;
  const HomeMonthlyAbsenceCalendarWidget({super.key, required this.absences});

  @override
  State<HomeMonthlyAbsenceCalendarWidget> createState() => _HomeMonthlyAbsenceCalendarWidgetState();
}

class _HomeMonthlyAbsenceCalendarWidgetState extends State<HomeMonthlyAbsenceCalendarWidget> {
  DateTime _shownMonth = DateTime.now();
  DateTime? _selectedDate;

  final Map<String, List<AbsenceModel>> _groupedByDay = {};

  @override
  void initState() {
    super.initState();
    _groupAbsences();
    // Seleciona automaticamente o dia mais recente de falta, se houver
    if (widget.absences.isNotEmpty) {
      // Ordena as ausências por data decrescente e pega a mais recente
      final mostRecent = widget.absences.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
      _selectedDate = mostRecent.date;
      _shownMonth = DateTime(mostRecent.date.year, mostRecent.date.month);
    }
  }

  @override
  void didUpdateWidget(covariant HomeMonthlyAbsenceCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.absences != widget.absences) {
      _groupAbsences();
      // Atualiza seleção se mudou a lista de ausências
      if (widget.absences.isNotEmpty) {
        final mostRecent = widget.absences.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
        setState(() {
          _selectedDate = mostRecent.date;
          _shownMonth = DateTime(mostRecent.date.year, mostRecent.date.month);
        });
      } else {
        setState(() {
          _selectedDate = null;
        });
      }
    }
  }

  void _groupAbsences() {
    _groupedByDay.clear();
    for (final a in widget.absences) {
      final key = '${a.date.year}-${a.date.month.toString().padLeft(2,'0')}-${a.date.day.toString().padLeft(2,'0')}';
      _groupedByDay.putIfAbsent(key, () => []).add(a);
    }
  }

  void _prevMonth() {
    setState(() {
      _shownMonth = DateTime(_shownMonth.year, _shownMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _shownMonth = DateTime(_shownMonth.year, _shownMonth.month + 1);
    });
  }

  /// Gera uma lista de dias para o calendário mensal, SEM domingos, alinhando sempre na segunda-feira
  List<DateTime> _daysInMonth(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    // Lista de todos os dias do mês, ignorando domingos
    final monthDays = <DateTime>[];
    for (int i = 0; i < lastDayOfMonth.day; i++) {
      final d = DateTime(month.year, month.month, i + 1);
      if (d.weekday != DateTime.sunday) {
        monthDays.add(d);
      }
    }
    // Descobre em que coluna (0=segunda, 5=sábado) começa o primeiro dia do mês
    int startCol = (firstDayOfMonth.weekday - DateTime.monday) % 7;
    if (startCol < 0) startCol += 6;
    // Preenche dias "vazios" antes do mês (do mês anterior, ignorando domingos)
    if (startCol > 0) {
      final prevMonth = DateTime(month.year, month.month - 1, 1);
      final lastDayPrevMonth = DateTime(prevMonth.year, prevMonth.month + 1, 0);
      final prevMonthDays = <DateTime>[];
      for (int i = 0; prevMonthDays.length < startCol; i++) {
        final d = DateTime(prevMonth.year, prevMonth.month, lastDayPrevMonth.day - i);
        if (d.weekday != DateTime.sunday) {
          prevMonthDays.insert(0, d);
        }
      }
      monthDays.insertAll(0, prevMonthDays);
    }
    // Preenche dias "vazios" após o fim do mês para completar a última semana (6 colunas)
    int remainder = monthDays.length % 6;
    int trailing = remainder == 0 ? 0 : 6 - remainder;
    if (trailing > 0 && trailing < 6) {
      final nextMonth = DateTime(month.year, month.month + 1, 1);
      final nextMonthDays = <DateTime>[];
      for (int i = 0; nextMonthDays.length < trailing; i++) {
        final d = DateTime(nextMonth.year, nextMonth.month, i + 1);
        if (d.weekday != DateTime.sunday) {
          nextMonthDays.add(d);
        }
      }
      monthDays.addAll(nextMonthDays);
    }
    return monthDays;
  }

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectProvider>().subjects;
    final Map<String, String> subjectNameById = {for (final s in subjects) s.id: s.name};
  final days = _daysInMonth(_shownMonth);
    final today = DateTime.now();

    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Calendário', style: AppTextStyles.sectionTitle(context)),
            const SizedBox(height: 8),
            CalendarHeader(
              shownMonth: _shownMonth,
              onPrevMonth: _prevMonth,
              onNextMonth: _nextMonth,
            ),
            const SizedBox(height: 12),
            // Weekday headers (Mon..Sat) - Sundays removed to save space
            Row(
              children: [
                for (final name in ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'])
                  Expanded(
                    child: Center(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(180), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            CalendarDayGrid(
              days: days,
              today: today,
              selectedDate: _selectedDate,
              groupedByDay: _groupedByDay,
              onSelectDate: (d) {
                setState(() {
                  _selectedDate = d;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_selectedDate == null)
              const Text('Selecione um dia com faltas para ver detalhes', textAlign: TextAlign.center),
            if (_selectedDate != null) ...[
              const SizedBox(height: 8),
              Center(child: Text('Faltas do dia ${_selectedDate!.day}/${_selectedDate!.month}', style: Theme.of(context).textTheme.titleMedium)),
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final list = _groupedByDay['${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2,'0')}-${_selectedDate!.day.toString().padLeft(2,'0')}'] ?? [];
                return AbsenceDayDetails(absences: list, subjectNameById: subjectNameById);
              }),
            ],
          ],
        ),
      ),
    );
  }
}
