import '../../../../shared/widgets/layout/spacings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/models/subject_model.dart';
import '../../../../shared/models/absence_model.dart';
import '../../../../shared/widgets/common/dialog_header.dart';
import '../providers/absence_provider.dart';
import '../../../subjects/presentation/providers/subject_provider.dart';
import '../../../../core/constants/design_constants.dart';
import '../../../../core/utils/utils_exports.dart';
import 'week_navigator.dart';
import 'quantity_selector.dart';

class RemoveAbsenceDialog extends StatefulWidget {
  final SubjectModel subject;

  const RemoveAbsenceDialog({
    super.key,
    required this.subject,
  });

  @override
  State<RemoveAbsenceDialog> createState() => _RemoveAbsenceDialogState();
}

class _RemoveAbsenceDialogState extends State<RemoveAbsenceDialog> {
  late final Set<int> _allowedWeekdays;
  final _quantityController = TextEditingController();
  final Set<DateTime> _selectedDates = {};
  bool _isLoading = false;
  bool _isLoadingAbsences = true;
  DateTime _currentWeekStart = DateTime.now();
  List<DateTime> _weekDays = [];
  final Map<String, int> _absencesPerDay = {};
  final Map<String, List<String>> _absenceIdsPerDay = {};
  final Map<String, AbsenceModel> _absencesById = {}; // Armazena objetos de ausência por ID

  @override
  void initState() {
  super.initState();
  _weekDays = AppDateUtils.generateWeekDays(_currentWeekStart);
  _allowedWeekdays = widget.subject.classSchedules.map((s) => s.weekday).toSet();
  _loadMonthAbsences();
  _quantityController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _quantityController.dispose();
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
        _absenceIdsPerDay.clear();
        _absencesById.clear();
        
        for (final absence in subjectAbsences) {
          final dateKey = AppDateUtils.formatDateKey(absence.date);
          _absencesPerDay[dateKey] = (_absencesPerDay[dateKey] ?? 0) + absence.quantity;
          
          if (!_absenceIdsPerDay.containsKey(dateKey)) {
            _absenceIdsPerDay[dateKey] = [];
          }
          _absenceIdsPerDay[dateKey]!.add(absence.id);
          _absencesById[absence.id] = absence; // Armazena o objeto completo
        }
        
        if (mounted) setState(() => _isLoadingAbsences = false);
        return; // Retorna instantaneamente!
      }
      
      // Caso contrário, carrega do backend
      await provider.loadSubjectAbsences(widget.subject.id);
      
      _absencesPerDay.clear();
      _absenceIdsPerDay.clear();
      _absencesById.clear();
      
      for (final absence in provider.subjectAbsences) {
        final dateKey = AppDateUtils.formatDateKey(absence.date);
        _absencesPerDay[dateKey] = (_absencesPerDay[dateKey] ?? 0) + absence.quantity;
        
        if (!_absenceIdsPerDay.containsKey(dateKey)) {
          _absenceIdsPerDay[dateKey] = [];
        }
        _absenceIdsPerDay[dateKey]!.add(absence.id);
        _absencesById[absence.id] = absence; // Armazena o objeto completo
      }
      
      if (mounted) setState(() => _isLoadingAbsences = false);
    } catch (e) {
      if (mounted) setState(() => _isLoadingAbsences = false);
    }
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = AppDateUtils.getPreviousWeek(_currentWeekStart);
      _selectedDates.clear();
      _quantityController.clear();
      _weekDays = AppDateUtils.generateWeekDays(_currentWeekStart);
    });
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = AppDateUtils.getNextWeek(_currentWeekStart);
      _selectedDates.clear();
      _quantityController.clear();
      _weekDays = AppDateUtils.generateWeekDays(_currentWeekStart);
    });
  }

  void _onDaySelected(DateTime day) {
    final dateKey = AppDateUtils.formatDateKey(day);
    final absenceCount = _absencesPerDay[dateKey] ?? 0;
    
    if (absenceCount == 0) return;

    setState(() {
      // Toggle selection
      if (_selectedDates.any((d) => AppDateUtils.isSameDay(d, day))) {
        _selectedDates.removeWhere((d) => AppDateUtils.isSameDay(d, day));
      } else {
        _selectedDates.add(day);
      }

      // Update max quantity based on minimum absences across selected days
      if (_selectedDates.isNotEmpty) {
        final minAbsences = _selectedDates.map((date) {
          final key = AppDateUtils.formatDateKey(date);
          return _absencesPerDay[key] ?? 0;
        }).reduce((a, b) => a < b ? a : b);

        // Update controller if current value exceeds new max
        final currentValue = int.tryParse(_quantityController.text) ?? 0;
        if (currentValue > minAbsences || _quantityController.text.isEmpty) {
          _quantityController.text = minAbsences.toString();
        }
      } else {
        _quantityController.clear();
      }
    });
  }

  Future<void> _handleSubmit() async {
    final quantity = int.tryParse(_quantityController.text);
    
    if (quantity == null || quantity < 1) {
      SnackBarHelper.showError(context, 'Informe uma quantidade válida');
      return;
    }
    
    if (_selectedDates.isEmpty) {
      SnackBarHelper.showWarning(context, 'Selecione pelo menos um dia');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final quantityToRemove = int.parse(_quantityController.text);
      final absenceProvider = context.read<AbsenceProvider>();
      final subjectProvider = context.read<SubjectProvider>();

      int totalRemoved = 0;

      // Remove absences from each selected date
      for (final date in _selectedDates) {
        final dateKey = AppDateUtils.formatDateKey(date);
        final totalAbsences = _absencesPerDay[dateKey] ?? 0;

        if (quantityToRemove > totalAbsences) {
          throw Exception('Quantidade a remover excede o total de faltas em ${AppDateUtils.formatDateKey(date)}');
        }

        final absenceIds = List<String>.from(_absenceIdsPerDay[dateKey] ?? []);
        int remainingToRemove = quantityToRemove;

        for (final absenceId in absenceIds) {
          if (remainingToRemove <= 0) break;
          final absence = _absencesById[absenceId];
          if (absence == null) {
            throw Exception('Ausência não encontrada no cache local');
          }
          if (remainingToRemove >= absence.quantity) {
            // Remove o registro inteiro
            await absenceProvider.deleteAbsence(
              absenceId,
              onAbsenceDeleted: (subjectId, qty) {
                subjectProvider.decrementAbsenceCount(subjectId, qty);
              },
            );
            totalRemoved += absence.quantity;
            remainingToRemove -= absence.quantity;
          } else {
            // Atualiza o registro com a nova quantidade
            final updated = absence.copyWith(quantity: absence.quantity - remainingToRemove);
            await absenceProvider.updateAbsence(
              updated,
              onAbsenceUpdated: (subjectId, oldQty, newQty) {
                final diff = oldQty - newQty;
                subjectProvider.decrementAbsenceCount(subjectId, diff);
              },
            );
            totalRemoved += remainingToRemove;
            remainingToRemove = 0;
          }
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        SnackBarHelper.showSuccess(
          context,
          totalRemoved == 1
              ? 'Falta removida com sucesso'
              : '$totalRemoved faltas removidas com sucesso',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Erro ao remover falta: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                      icon: Icons.remove_circle_outline,
                      title: 'Remover Falta',
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WeekNavigator(
                      weekDays: _weekDays,
                      multipleSelection: true,
                      selectedDates: _selectedDates,
                      absencesPerDay: _absencesPerDay,
                      isLoading: _isLoadingAbsences,
                      onPreviousWeek: _previousWeek,
                      onNextWeek: _nextWeek,
                      onDaySelected: _onDaySelected,
                      enableOnlyWithAbsences: true,
                      allowedWeekdays: _allowedWeekdays,
                    ),
                    const SectionSpacing(),
                    if (!_isLoadingAbsences) ...[
                      Text(
                        'Quantidade de Faltas a Remover',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: DesignConstants.sm),
                      QuantitySelector(
                        controller: _quantityController,
                        maxValue: _selectedDates.isNotEmpty
                            ? _selectedDates.map((date) {
                                final key = AppDateUtils.formatDateKey(date);
                                return _absencesPerDay[key] ?? 0;
                              }).reduce((a, b) => a < b ? a : b)
                            : null,
                        helperText: _selectedDates.isNotEmpty
                            ? 'Máximo: ${_selectedDates.map((date) {
                                final key = AppDateUtils.formatDateKey(date);
                                return _absencesPerDay[key] ?? 0;
                              }).reduce((a, b) => a < b ? a : b)} falta(s) (menor valor entre os dias selecionados)'
                            : null,
                      ),
                    ],
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
                            : const Icon(Icons.delete_outline),
                        label: Text(
                          _isLoading ? 'Removendo...' : 'Remover Falta(s)',
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
          ],
        ),
      ),
    );
  }
}
