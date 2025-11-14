import '../../../../shared/widgets/layout/spacings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../shared/models/subject_model.dart';
import '../../../../shared/models/class_schedule_model.dart';
import '../../../../shared/widgets/common/dialog_header.dart';
import '../../../../shared/widgets/common/delete_confirmation_dialog.dart';
import '../../../../shared/widgets/form_fields/dialog_text_field.dart';
import '../../../../core/utils/utils_exports.dart';
import '../../../../core/constants/design_constants.dart';
import '../providers/subject_provider.dart';
import 'weekday_selector.dart';
import 'weekday_schedule_selector.dart';

class EditSubjectDialog extends StatefulWidget {
  final SubjectModel subject;

  const EditSubjectDialog({
    super.key,
    required this.subject,
  });

  @override
  State<EditSubjectDialog> createState() => _EditSubjectDialogState();
}

class _EditSubjectDialogState extends State<EditSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _maxAbsencesController;
  final _nameFocusNode = FocusNode();
  final _maxAbsencesFocusNode = FocusNode();
  
  late Set<int> _selectedWeekdays;
  late Map<int, List<TimeOfDay>> _weekdaySchedules;
  
  bool _isSubmitting = false;
  bool _hasChanges = false;

  static const _weekdayFullNames = {
    1: 'Segunda-feira',
    2: 'Terça-feira',
    3: 'Quarta-feira',
    4: 'Quinta-feira',
    5: 'Sexta-feira',
    6: 'Sábado',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject.name);
    _maxAbsencesController = TextEditingController(
      text: widget.subject.maxAbsences.toString(),
    );
    
    // Inicializar dias e horários a partir da matéria existente
    _selectedWeekdays = {};
    _weekdaySchedules = {};
    
    for (final schedule in widget.subject.classSchedules) {
      _selectedWeekdays.add(schedule.weekday);
      
      // Converter "HH:mm" para TimeOfDay
      final parts = schedule.startTime.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          final timeOfDay = TimeOfDay(hour: hour, minute: minute);
          
          if (_weekdaySchedules.containsKey(schedule.weekday)) {
            _weekdaySchedules[schedule.weekday]!.add(timeOfDay);
          } else {
            _weekdaySchedules[schedule.weekday] = [timeOfDay];
          }
        }
      }
    }
    
    // Detectar mudanças nos campos
    _nameController.addListener(_checkForChanges);
    _maxAbsencesController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkForChanges);
    _maxAbsencesController.removeListener(_checkForChanges);
    _nameController.dispose();
    _maxAbsencesController.dispose();
    _nameFocusNode.dispose();
    _maxAbsencesFocusNode.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final nameChanged = _nameController.text != widget.subject.name;
    final maxAbsencesChanged = 
        _maxAbsencesController.text != widget.subject.maxAbsences.toString();
    
    // Verificar se os horários mudaram
    bool schedulesChanged = false;
    final currentSchedules = widget.subject.classSchedules;
    
    // Verificar se a quantidade de dias mudou
    final currentWeekdays = currentSchedules.map((s) => s.weekday).toSet();
    if (!_selectedWeekdays.containsAll(currentWeekdays) || 
        !currentWeekdays.containsAll(_selectedWeekdays)) {
      schedulesChanged = true;
    } else {
      // Verificar se os horários de cada dia mudaram
      for (final weekday in _selectedWeekdays) {
        final currentTimes = currentSchedules
            .where((s) => s.weekday == weekday)
            .map((s) => s.startTime)
            .toList()
            ..sort();
        
        final newTimes = (_weekdaySchedules[weekday] ?? [])
            .map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
            .toList()
            ..sort();
        
        if (currentTimes.length != newTimes.length ||
            !currentTimes.every((t) => newTimes.contains(t))) {
          schedulesChanged = true;
          break;
        }
      }
    }
    
    setState(() {
      _hasChanges = nameChanged || maxAbsencesChanged || schedulesChanged;
    });
  }

  void _toggleWeekday(int weekday) {
    setState(() {
      if (_selectedWeekdays.contains(weekday)) {
        _selectedWeekdays.remove(weekday);
        _weekdaySchedules.remove(weekday);
      } else {
        _selectedWeekdays.add(weekday);
      }
      _checkForChanges();
    });
  }

  void _updateSchedule(int weekday, List<TimeOfDay> times) {
    setState(() {
      if (times.isNotEmpty) {
        _weekdaySchedules[weekday] = times;
      } else {
        _weekdaySchedules.remove(weekday);
      }
      _checkForChanges();
    });
  }

  bool get _isFormValid {
    return _nameController.text.isNotEmpty &&
        _maxAbsencesController.text.isNotEmpty &&
        _selectedWeekdays.isNotEmpty &&
        _selectedWeekdays.every((weekday) => 
          _weekdaySchedules.containsKey(weekday) && 
          _weekdaySchedules[weekday]!.isNotEmpty
        );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isFormValid) return;

    setState(() => _isSubmitting = true);

    // Converter os horários para ClassScheduleModel
    final classSchedules = <ClassScheduleModel>[];
    _weekdaySchedules.forEach((weekday, times) {
      for (final time in times) {
        final hour = time.hour.toString().padLeft(2, '0');
        final minute = time.minute.toString().padLeft(2, '0');
        final startTime = '$hour:$minute';
        
        classSchedules.add(
          ClassScheduleModel(
            weekday: weekday,
            startTime: startTime,
          ),
        );
      }
    });

    try {
      final provider = context.read<SubjectProvider>();
      final updatedSubject = widget.subject.copyWith(
        name: _nameController.text.trim(),
        maxAbsences: int.parse(_maxAbsencesController.text),
        classSchedules: classSchedules,
      );
      
      final success = await provider.updateSubject(updatedSubject);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
        SnackBarHelper.showSuccess(context, 'Matéria atualizada com sucesso!');
      } else {
        SnackBarHelper.showError(
          context,
          provider.error ?? 'Erro ao atualizar matéria',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deleteSubject() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: 'Excluir Matéria',
        message: 
            'Tem certeza que deseja excluir "${widget.subject.name}"? '
            'Esta ação não pode ser desfeita.',
        confirmText: 'Excluir',
        onConfirm: () async {
          final provider = this.context.read<SubjectProvider>();
          await provider.deleteSubject(widget.subject.id);
        },
      ),
    );

    if (result == true && mounted) {
      Navigator.of(context).pop(true);
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
                      icon: Icons.edit,
                      title: 'Editar Matéria',
                      subtitle: 'Atualize as informações',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
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
                      DialogTextField(
                        labelText: 'Nome da Matéria',
                        hintText: 'Ex: Circuitos Digitais, Cálculo I...',
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        validator: ValidationHelper.validateSubjectName,
                        enabled: !_isSubmitting,
                        textCapitalization: TextCapitalization.words,
                        onFieldSubmitted: (_) => _maxAbsencesFocusNode.requestFocus(),
                      ),
                      const SizedBox(height: DesignConstants.md),
                      DialogTextField(
                        labelText: 'Máximo de Faltas',
                        hintText: 'Ex: 15',
                        controller: _maxAbsencesController,
                        focusNode: _maxAbsencesFocusNode,
                        validator: ValidationHelper.validateMaxAbsences,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onFieldSubmitted: (_) {},
                      ),
                      const SizedBox(height: DesignConstants.lg),
                      Text(
                        'Dias da Semana',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: DesignConstants.sm),
                      WeekdaySelector(
                        selectedWeekdays: _selectedWeekdays,
                        onWeekdayToggle: _toggleWeekday,
                      ),
                      if (_selectedWeekdays.isNotEmpty) ...[
                        const SizedBox(height: DesignConstants.lg),
                        Text(
                          'Horários das Aulas',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: DesignConstants.sm),
                        ...List.generate(
                          _selectedWeekdays.length,
                          (index) {
                            final sortedWeekdays = _selectedWeekdays.toList()..sort();
                            final weekday = sortedWeekdays[index];
                            return WeekdayScheduleSelector(
                              weekdayName: _weekdayFullNames[weekday]!,
                              selectedTimes: _weekdaySchedules[weekday] ?? [],
                              onTimesChanged: (times) => _updateSchedule(weekday, times),
                            );
                          },
                        ),
                      ],
                      const SectionSpacing(),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: _isSubmitting ? null : _deleteSubject,
                              icon: const Icon(Icons.delete),
                              label: Text(
                                'Excluir',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  vertical: DesignConstants.buttonVertical,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: DesignConstants.sm),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: (_isSubmitting || !_isFormValid || !_hasChanges)
                                  ? null
                                  : _handleSubmit,
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                      ),
                                    )
                                  : const Icon(Icons.save, color: Colors.black),
                              label: Text(
                                _isSubmitting ? 'Salvando...' : 'Salvar Alterações',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
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

