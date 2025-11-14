import '../../../../shared/widgets/layout/spacings.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/models/subject_model.dart';
import '../providers/absence_provider.dart';
import '../../../subjects/presentation/providers/subject_provider.dart';
import '../../../../shared/widgets/form_fields/dialog_text_field.dart';
import '../../../../shared/widgets/common/dialog_header.dart';
import '../../../../core/constants/design_constants.dart';
import '../../../../core/utils/utils_exports.dart';
import 'week_navigator.dart';
import 'quantity_selector.dart';

class AddAbsenceDialog extends StatefulWidget {
  final SubjectModel subject;

  const AddAbsenceDialog({
    super.key,
    required this.subject,
  });

  @override
  State<AddAbsenceDialog> createState() => _AddAbsenceDialogState();
}

class _AddAbsenceDialogState extends State<AddAbsenceDialog> {
  late final Set<int> _allowedWeekdays;
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '2');
  final _reasonController = TextEditingController();
  final Set<DateTime> _selectedDates = {}; // Múltiplas datas
  bool _isLoading = false;
  bool _isLoadingAbsences = true;
  DateTime _currentWeekStart = DateTime.now();
  List<DateTime> _weekDays = [];
  final Map<String, int> _absencesPerDay = {};

  @override
  void initState() {
  super.initState();
  _weekDays = AppDateUtils.generateWeekDays(_currentWeekStart);
  _allowedWeekdays = widget.subject.classSchedules.map((s) => s.weekday).toSet();
  _loadMonthAbsences();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadMonthAbsences() async {
    setState(() => _isLoadingAbsences = true);
    
    try {
      final provider = context.read<AbsenceProvider>();
      
      // OTIMIZAÇÃO: Se já temos todas as faltas do usuário, usa filtro local
      if (provider.hasSubjectAbsencesLoaded(widget.subject.id)) {
        // Dados já estão carregados! Filtra localmente sem chamada ao backend
        final subjectAbsences = provider.getSubjectAbsencesLocally(widget.subject.id);
        
        _absencesPerDay.clear();
        for (final absence in subjectAbsences) {
          final dateKey = AppDateUtils.formatDateKey(absence.date);
          _absencesPerDay[dateKey] = (_absencesPerDay[dateKey] ?? 0) + absence.quantity;
        }
        
        if (mounted) setState(() => _isLoadingAbsences = false);
        return; // Retorna instantaneamente!
      }
      
      // Caso contrário, carrega do backend
      await provider.loadSubjectAbsences(widget.subject.id);
      
      _absencesPerDay.clear();
      for (final absence in provider.subjectAbsences) {
        final dateKey = AppDateUtils.formatDateKey(absence.date);
        _absencesPerDay[dateKey] = (_absencesPerDay[dateKey] ?? 0) + absence.quantity;
      }
      
      if (mounted) setState(() => _isLoadingAbsences = false);
    } catch (e) {
      if (mounted) setState(() => _isLoadingAbsences = false);
    }
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = AppDateUtils.getPreviousWeek(_currentWeekStart);
      _weekDays = AppDateUtils.generateWeekDays(_currentWeekStart);
    });
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = AppDateUtils.getNextWeek(_currentWeekStart);
      _weekDays = AppDateUtils.generateWeekDays(_currentWeekStart);
    });
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      if (_selectedDates.contains(day)) {
        _selectedDates.remove(day); // Deselecionar se já estava selecionado
      } else {
        _selectedDates.add(day); // Adicionar à seleção
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDates.isEmpty) {
      SnackBarHelper.showError(context, 'Selecione pelo menos um dia da semana');
      return;
    }

    // Validar quantidade máxima
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (quantity < 1) {
      return;
    }
    if (quantity > 10) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final reason = _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim();

      final absenceProvider = context.read<AbsenceProvider>();
      final subjectProvider = context.read<SubjectProvider>();
      
      // Criar uma falta para cada dia selecionado
      int successCount = 0;
      int failCount = 0;
      
      for (final date in _selectedDates) {
        final success = await absenceProvider.createAbsence(
          subjectId: widget.subject.id,
          date: date,
          quantity: quantity,
          reason: reason,
          // Atualização otimista - não precisa recarregar tudo
          onAbsenceCreated: (subjectId, qty) {
            subjectProvider.incrementAbsenceCount(subjectId, qty);
          },
        );
        
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      }

      if (mounted) {
        // Fecha o dialog primeiro
        Navigator.of(context).pop(true);
        
        // Aguarda um pouco antes de mostrar snackbar
        // para dar tempo das animações acontecerem
        await Future.delayed(const Duration(milliseconds: 200));
        
        if (!mounted) return;
        
        // Mensagem de sucesso com contagem
        final totalAbsences = successCount * quantity;
        final daysText = successCount == 1 ? 'dia' : 'dias';
        
        if (failCount == 0) {
          SnackBarHelper.showSuccess(
            context,
            '$totalAbsences falta(s) registrada(s) em $successCount $daysText',
          );
        } else {
          SnackBarHelper.showWarning(
            context,
            '$successCount $daysText registrado(s), $failCount falharam',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Erro ao registrar faltas: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignConstants.radiusLg),
      ),
      child: SizedBox(
        width: DesignConstants.dialogWidthMedium,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignConstants.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(DesignConstants.radiusLg),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DialogHeader(
                      icon: Icons.add_circle_outline,
                      title: 'Adicionar Falta',
                      subtitle: widget.subject.name,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Fechar',
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(DesignConstants.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WeekNavigator(
                        weekDays: _weekDays,
                        selectedDates: _selectedDates, // Seleção múltipla
                        absencesPerDay: _absencesPerDay,
                        isLoading: _isLoadingAbsences,
                        onPreviousWeek: _previousWeek,
                        onNextWeek: _nextWeek,
                        onDaySelected: _onDaySelected,
                        multipleSelection: true, // Habilitar seleção múltipla
                        showAbsenceBorder: false, // Não mostrar borda vermelha de faltas
                        allowedWeekdays: _allowedWeekdays,
                      ),
                      const SectionSpacing(),
                      Text(
                        'Quantidade de Faltas',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: DesignConstants.sm),
                      QuantitySelector(
                        controller: _quantityController,
                        maxValue: 10,
                      ),
                      const ElementSpacing(),
                      DialogTextField(
                        labelText: 'Motivo (opcional)',
                        hintText: 'Ex: Consulta médica',
                        controller: _reasonController,
                        validator: ValidationHelper.validateAbsenceReason,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(20),
                        ],
                      ),
                      const SectionSpacing(),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: (_isLoading || _isLoadingAbsences || _selectedDates.isEmpty) 
                              ? null 
                              : _handleSubmit,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: Text(
                            _isLoading ? 'Adicionando...' : 'Adicionar Falta',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: Colors.grey.shade700,
                            disabledForegroundColor: Colors.grey.shade500,
                            padding: const EdgeInsets.symmetric(
                              vertical: DesignConstants.buttonVertical,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DesignConstants.radiusSm),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
