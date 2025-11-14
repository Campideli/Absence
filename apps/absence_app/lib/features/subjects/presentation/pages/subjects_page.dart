import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subject_provider.dart';
import '../widgets/create_subject_dialog.dart';
import '../widgets/edit_subject_dialog.dart';
import '../widgets/subject_card.dart';
import '../widgets/import_schedule_dialog.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart' as dashboard;
import '../../../../shared/widgets/buttons/primary_action_button.dart';
import '../../../../shared/widgets/layout/page_container.dart';
import '../../../../core/theme/theme_exports.dart';
import '../../../../shared/widgets/layout/spacings.dart';
import '../../../../shared/models/subject_model.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  void _showImportScheduleDialog(BuildContext context) async {
    final result = await showDialog<List<SubjectModel>>(
      context: context,
      builder: (context) => const ImportScheduleDialog(),
    );
    
    if (result != null && result.isNotEmpty && mounted) {
      final provider = context.read<SubjectProvider>();
      
      // Show loading while saving
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Salvando matérias...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        // Save each subject
        for (final subject in result) {
          await provider.createSubject(
            name: subject.name,
            maxAbsences: subject.maxAbsences,
            classSchedules: subject.classSchedules,
          );
        }
        
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.length} matérias importadas com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar matérias: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SubjectProvider>();
      // Carrega apenas se nunca foi carregado
      if (provider.isInitial) {
        provider.loadSubjects();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppDecorations.transparentAppBar(
        title: 'Matérias',
        context: context,
      ),
      body: Consumer<SubjectProvider>(
        builder: (context, provider, child) {
          // Mostra loading se está carregando E (é inicial OU não há dados ainda)
          if (provider.isLoading && (provider.isInitial || provider.subjects.isEmpty)) {
            return const dashboard.AppLoadingWidget();
          }

          if (provider.hasError && provider.error != null) {
            return dashboard.AppErrorWidget(
              message: provider.error!,
              onRetry: () => provider.loadSubjects(),
            );
          }

          return SingleChildScrollView(
            child: PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionSpacing(),
                  // Botão Importar Horário UEM
                  PrimaryActionButton(
                    label: 'Importar horário UEM',
                    icon: Icons.file_upload_outlined,
                    onPressed: () => _showImportScheduleDialog(context),
                  ),
                  const ElementSpacing(),
                  // Botão Adicionar Matéria
                  PrimaryActionButton(
                    label: 'Adicionar Matéria',
                    icon: Icons.add,
                    onPressed: () => _showCreateSubjectDialog(context),
                  ),
                  const SectionSpacing(),
                  // Lista de Matérias
                    if (provider.subjects.isEmpty)
                      AppDecorations.responsiveContainer(
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
                                'Cadastre matérias primeiro para visualizar ou registrar horários e faltas',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.emptyStateSubtitle(context),
                              ),
                            ],
                          ),
                        ),
                      )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.subjects.length,
                      itemBuilder: (context, index) {
                        final subject = provider.subjects[index];
                        return SubjectCard(
                          key: ValueKey(subject.id),
                          subject: subject,
                          onTap: () => _showSubjectDetails(context, subject),
                          onEdit: () => _showSubjectDetails(context, subject),
                          // onDelete pode ser implementado futuramente
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

  void _showCreateSubjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateSubjectDialog(),
    );
  }

  void _showSubjectDetails(BuildContext context, SubjectModel subject) {
    showDialog(
      context: context,
      builder: (context) => EditSubjectDialog(subject: subject),
    );
  }
}

// _SubjectListItem removido: substituído por SubjectCard
