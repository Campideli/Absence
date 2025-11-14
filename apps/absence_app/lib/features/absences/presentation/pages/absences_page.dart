import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/absence_provider.dart';
import '../../../subjects/presentation/providers/subject_provider.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart' as dashboard;
import '../../../../shared/models/subject_model.dart';
import '../../../../core/theme/theme_exports.dart';
import '../../../../shared/widgets/layout/spacings.dart';
import '../../../../shared/widgets/layout/page_container.dart';
import '../widgets/subject_absence_card.dart';
import '../widgets/add_absence_dialog.dart';
import '../widgets/remove_absence_dialog.dart';

// Classe para otimizar rebuilds da página de Absences
class _AbsencePageData {
  final List<SubjectModel> subjects;
  final bool isLoading;
  final bool hasError;
  final String? error;

  const _AbsencePageData({
    required this.subjects,
    required this.isLoading,
    required this.hasError,
    this.error,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _AbsencePageData) return false;
    
    // Compara estados de loading e erro
    if (isLoading != other.isLoading ||
        hasError != other.hasError ||
        error != other.error) {
      return false;
    }
    
    // Compara tamanho da lista
    if (subjects.length != other.subjects.length) {
      return false;
    }
    
    // Compara conteúdo: verifica se algum currentAbsences, absencePercentage ou status mudou
    for (var i = 0; i < subjects.length; i++) {
      final s1 = subjects[i];
      final s2 = other.subjects[i];
      if (s1.id != s2.id ||
          s1.currentAbsences != s2.currentAbsences ||
          s1.absencePercentage != s2.absencePercentage ||
          s1.status != s2.status ||
          s1.name != s2.name) {
        return false;
      }
    }
    
    return true;
  }

  @override
  int get hashCode =>
      subjects.length.hashCode ^
      isLoading.hashCode ^
      hasError.hashCode ^
      error.hashCode;
}

class AbsencesPage extends StatefulWidget {
  const AbsencesPage({super.key});

  @override
  State<AbsencesPage> createState() => _AbsencesPageState();
}

class _AbsencesPageState extends State<AbsencesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subjectProvider = context.read<SubjectProvider>();
      final absenceProvider = context.read<AbsenceProvider>();
      
      // Carrega absences apenas se nunca foi carregado
      if (absenceProvider.isInitial) {
        absenceProvider.loadUserAbsences();
      }
      
      // Carrega subjects apenas se nunca foi carregado
      // A ordenação por proximidade é garantida pelo getter subjectsByProximity
      if (subjectProvider.isInitial) {
        subjectProvider.loadSubjectsByProximity();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppDecorations.transparentAppBar(
        title: 'Faltas',
        context: context,
      ),
      // Usa Selector para só rebuild quando subjects mudarem
      body: Selector<SubjectProvider, _AbsencePageData>(
        selector: (context, provider) => _AbsencePageData(
          subjects: provider.subjectsByProximity,
          isLoading: provider.isLoading && (provider.isInitial || provider.subjects.isEmpty),
          hasError: provider.hasError,
          error: provider.error,
        ),
        builder: (context, data, child) {
          // Mostra loading se está carregando E (é inicial OU não há dados ainda)
          if (data.isLoading) {
            return const dashboard.AppLoadingWidget();
          }
          
          if (data.hasError && data.error != null) {
            return dashboard.AppErrorWidget(
              message: data.error!,
              onRetry: () {
                context.read<SubjectProvider>().loadSubjectsByProximity();
                context.read<AbsenceProvider>().loadUserAbsences();
              },
            );
          }

          if (data.subjects.isEmpty) {
            return AppDecorations.responsiveContainer(
              child: AppDecorations.emptyStateContainer(
                context: context,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppDecorations.emptyStateIcon(
                      icon: Icons.school_outlined,
                      context: context,
                    ),
                    const SectionSpacing(),
                    Text(
                      'Nenhuma matéria cadastrada',
                      style: AppTextStyles.emptyStateTitle(context),
                    ),
                    const TextSpacing(),
                    Text(
                      'Cadastre matérias primeiro para registrar faltas',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.emptyStateSubtitle(context),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionSpacing(),
                  // Título
                  Text(
                    'Minhas Matérias',
                    style: AppTextStyles.sectionTitle(context),
                  ),
                  const TextSpacing(),
                  Text(
                    'Gerencie as faltas de cada matéria',
                    style: AppTextStyles.pageSubtitle(context),
                  ),
                  const ElementSpacing(),
                  // Lista de cards de matérias
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.subjects.length,
                    itemBuilder: (context, index) {
                      final subject = data.subjects[index];
                      return SubjectAbsenceCard(
                        key: ValueKey(subject.id),
                        subject: subject,
                        onAddAbsence: () => _showAddAbsenceDialog(subject),
                        onRemoveAbsence: () => _showRemoveAbsenceDialog(subject),
                      );
                    },
                  ),
                  const SectionSpacing(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddAbsenceDialog(SubjectModel subject) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => AddAbsenceDialog(subject: subject),
    );
    
    // Não precisa recarregar! A atualização é otimista via callbacks
    // O SubjectProvider já foi atualizado pelo incrementAbsenceCount
  }

  Future<void> _showRemoveAbsenceDialog(SubjectModel subject) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => RemoveAbsenceDialog(subject: subject),
    );
    
    // Não precisa recarregar! A atualização é otimista via callbacks
    // O SubjectProvider já foi atualizado pelo decrementAbsenceCount
  }
}
