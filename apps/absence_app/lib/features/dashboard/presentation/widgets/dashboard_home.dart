import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_exports.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart';
import '../../../../shared/models/subject_model.dart';
import '../../../../shared/models/absence_model.dart';
import '../../../subjects/presentation/providers/subject_provider.dart';
import '../../../absences/presentation/providers/absence_provider.dart';
import 'home_monthly_absence_calendar_widget.dart';
import 'top_absence_subjects_preview.dart';
import 'today_schedule_preview.dart';
import 'dashboard_greeting.dart';
import '../../../../shared/widgets/layout/page_container.dart';
import '../pages/dashboard_page.dart';
import '../../../../shared/widgets/layout/spacings.dart';

// Classe para otimizar rebuilds do Dashboard
class _DashboardData {
  final List<SubjectModel> subjects;
  final List<AbsenceModel> absences;
  final bool subjectLoading;
  final bool absenceLoading;
  final bool hasError;
  final String? error;

  const _DashboardData({
    required this.subjects,
    required this.absences,
    required this.subjectLoading,
    required this.absenceLoading,
    required this.hasError,
    this.error,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _DashboardData) return false;
    
    // Compara estados de loading e erro
    if (subjectLoading != other.subjectLoading ||
        absenceLoading != other.absenceLoading ||
        hasError != other.hasError ||
        error != other.error) {
      return false;
    }
    
    // Compara tamanhos das listas
    if (subjects.length != other.subjects.length ||
        absences.length != other.absences.length) {
      return false;
    }
    
    // Compara conteúdo das listas verificando IDs e valores relevantes
    // Para subjects: verifica se algum currentAbsences, absencePercentage, status ou classSchedules mudou
    for (var i = 0; i < subjects.length; i++) {
      final s1 = subjects[i];
      final s2 = other.subjects[i];
      if (s1.id != s2.id ||
          s1.currentAbsences != s2.currentAbsences ||
          s1.absencePercentage != s2.absencePercentage ||
          s1.status != s2.status ||
          s1.classSchedules.length != s2.classSchedules.length) {
        return false;
      }
    }
    
    // Para absences: tamanho já é suficiente pois só muda quando adiciona/remove
    
    return true;
  }

  @override
  int get hashCode =>
      subjects.length.hashCode ^
      absences.length.hashCode ^
      subjectLoading.hashCode ^
      absenceLoading.hashCode ^
      hasError.hashCode ^
      error.hashCode;
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subjectProvider = context.read<SubjectProvider>();
      final absenceProvider = context.read<AbsenceProvider>();
      
      // Carrega apenas se nunca foi carregado
      if (subjectProvider.isInitial) {
        subjectProvider.loadSubjects();
      }
      if (absenceProvider.isInitial) {
        absenceProvider.loadUserAbsences();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppDecorations.transparentAppBar(
        title: 'Absence',
        context: context,
      ),
      // Usa Selector para só rebuild quando dados relevantes mudarem
      body: Selector2<SubjectProvider, AbsenceProvider, _DashboardData>(
        selector: (context, subjectProvider, absenceProvider) => _DashboardData(
          subjects: subjectProvider.subjects,
          absences: absenceProvider.absences,
          subjectLoading: subjectProvider.isLoading && (subjectProvider.isInitial || subjectProvider.subjects.isEmpty),
          absenceLoading: absenceProvider.isLoading && (absenceProvider.isInitial || absenceProvider.absences.isEmpty),
          hasError: subjectProvider.hasError,
          error: subjectProvider.error,
        ),
        builder: (context, data, child) {
          // Mostra loading se está carregando E (é inicial OU não há dados ainda)
          if (data.subjectLoading || data.absenceLoading) {
            return const AppLoadingWidget();
          }

          if (data.hasError && data.error != null) {
            return AppErrorWidget(
              message: data.error!,
              onRetry: () {
                context.read<SubjectProvider>().loadSubjects();
                context.read<AbsenceProvider>().loadUserAbsences();
              },
            );
          }

          // Layout principal: saudação extraída para DashboardGreeting
          return SingleChildScrollView(
            child: PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DashboardGreeting(),
                  TodaySchedulePreview(
                    onGoToSchedules: () {
                      final dashboardState = context.findAncestorStateOfType<DashboardPageState>();
                      if (dashboardState != null) {
                        dashboardState.setState(() {
                          dashboardState.setCurrentIndex(3);
                        });
                      }
                    },
                  ),
                  const SectionSpacing(),
                  TopAbsenceSubjectsPreview(
                    subjects: (data.subjects.toList()
                      ..sort((a, b) => b.absencePercentage.compareTo(a.absencePercentage))),
                  ),
                  const SectionSpacing(),
                  HomeMonthlyAbsenceCalendarWidget(absences: data.absences),
                  const SectionSpacing(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // DashboardHome now only shows CalendarMonthPage. Helper methods removed.
}