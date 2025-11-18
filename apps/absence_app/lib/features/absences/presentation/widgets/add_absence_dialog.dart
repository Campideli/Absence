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

      // Se já temos faltas carregadas localmente, usa o cache
      List absences;
      if (provider.hasSubjectAbsencesLoaded(widget.subject.id)) {
        absences = provider.getSubjectAbsencesLocally(widget.subject.id);
      } else {
        // Caso contrário, sincroniza com backend
        await provider.loadSubjectAbsences(widget.subject.id);
        absences = provider.subjectAbsences;
      }

      _absencesPerDay.clear();
      for (final absence in absences) {
        final dateKey = AppDateUtils.formatDateKey(absence.date);
        _absencesPerDay[dateKey] = ((_absencesPerDay[dateKey] ?? 0) + absence.quantity).toInt();
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

    setState(() {
      _isLoading = true;
      final absenceProvider = context.read<AbsenceProvider>();
      final reason = _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim();
      int totalAbsences = 0;
      for (final date in _selectedDates) {
        absenceProvider.addAbsenceLocally(
          subjectId: widget.subject.id,
          date: date,
          quantity: quantity,
          reason: reason,
        );
        final dateKey = AppDateUtils.formatDateKey(date);
        _absencesPerDay[dateKey] = (_absencesPerDay[dateKey] ?? 0) + quantity;
        totalAbsences += quantity;
      }
      // Atualiza o contador da matéria uma única vez
      final subjectProvider = context.read<SubjectProvider>();
      subjectProvider.incrementAbsenceCount(widget.subject.id, totalAbsences);
    });

    // Chama backend em segundo plano
    Future.microtask(() async {
      final absenceProvider = context.read<AbsenceProvider>();
      final reason = _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim();
      for (final date in _selectedDates) {
        await absenceProvider.createAbsence(
          subjectId: widget.subject.id,
          date: date,
          quantity: quantity,
          reason: reason,
        );
      }
    });

    if (mounted) {
      Navigator.of(context).pop(true);
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() => _isLoading = false);
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
