import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_decorations.dart';
import '../widgets/weekly_schedule_widget.dart';
import '../../../subjects/presentation/providers/subject_provider.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart' as dashboard;

// Page-level optimization data used by Selector
class _SchedulesPageData {
  final List subjects;
  final bool isLoading;
  final bool hasError;
  final String? error;

  const _SchedulesPageData({
    required this.subjects,
    required this.isLoading,
    required this.hasError,
    this.error,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _SchedulesPageData) return false;
    if (isLoading != other.isLoading || hasError != other.hasError || error != other.error) return false;
    if (subjects.length != other.subjects.length) return false;
    
    // Compara se os classSchedules de cada matéria mudaram
    for (var i = 0; i < subjects.length; i++) {
      final s1 = subjects[i];
      final s2 = other.subjects[i];
      if (s1.id != s2.id || s1.classSchedules.length != s2.classSchedules.length) {
        return false;
      }
    }
    
    return true;
  }

  @override
  int get hashCode => subjects.length.hashCode ^ isLoading.hashCode ^ hasError.hashCode ^ (error?.hashCode ?? 0);
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> with SingleTickerProviderStateMixin {


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subjectProvider = context.read<SubjectProvider>();
      if (subjectProvider.isInitial) {
        subjectProvider.loadSubjectsByProximity();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppDecorations.transparentAppBar(
        title: 'Horários',
        context: context,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Selector<SubjectProvider, _SchedulesPageData>(
          selector: (context, provider) => _SchedulesPageData(
            subjects: provider.subjects,
            isLoading: provider.isLoading && (provider.isInitial || provider.subjects.isEmpty),
            hasError: provider.hasError,
            error: provider.error,
          ),
          builder: (context, data, child) {
            if (data.isLoading) {
              return const dashboard.AppLoadingWidget();
            }

            if (data.hasError && data.error != null) {
              return dashboard.AppErrorWidget(
                message: data.error!,
                onRetry: () {
                  context.read<SubjectProvider>().loadSubjectsByProximity();
                },
              );
            }

            if (data.subjects.isEmpty) {
              return Center(
                child: AppDecorations.responsiveContainer(
                  child: AppDecorations.emptyStateContainer(
                    context: context,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppDecorations.emptyStateIcon(
                          icon: Icons.schedule_outlined,
                          context: context,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Nenhum horário cadastrado',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cadastre matérias primeiro para visualizar ou registrar horários',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  WeeklyScheduleWidget(),
                  SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
