import '../../../../shared/widgets/layout/spacings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/subject_provider.dart';
import '../../../../shared/widgets/form_fields/dialog_text_field.dart';
import '../../../../shared/widgets/common/dialog_header.dart';
import '../../../../core/utils/utils_exports.dart';
import '../../../../core/constants/design_constants.dart';
import '../../../../shared/models/class_schedule_model.dart';
import 'weekday_selector.dart';
import 'weekday_schedule_selector.dart';

class CreateSubjectDialog extends StatefulWidget {
  const CreateSubjectDialog({super.key});

  @override
  State<CreateSubjectDialog> createState() => _CreateSubjectDialogState();
}

class _CreateSubjectDialogState extends State<CreateSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _maxAbsencesController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _maxAbsencesFocusNode = FocusNode();
  
  final Set<int> _selectedWeekdays = {};
  final Map<int, List<TimeOfDay>> _weekdaySchedules = {};
  
  bool _isSubmitting = false;

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
    _nameController.addListener(() => setState(() {}));
    _maxAbsencesController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxAbsencesController.dispose();
    _nameFocusNode.dispose();
    _maxAbsencesFocusNode.dispose();
    super.dispose();
  }

  void _toggleWeekday(int weekday) {
    setState(() {
      if (_selectedWeekdays.contains(weekday)) {
        _selectedWeekdays.remove(weekday);
        _weekdaySchedules.remove(weekday);
      } else {
        _selectedWeekdays.add(weekday);
      }
    });
  }

  void _updateSchedule(int weekday, List<TimeOfDay> times) {
    setState(() {
      if (times.isNotEmpty) {
        _weekdaySchedules[weekday] = times;
      } else {
        _weekdaySchedules.remove(weekday);
      }
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

    final provider = context.read<SubjectProvider>();
    final success = await provider.createSubject(
      name: _nameController.text,
      maxAbsences: int.parse(_maxAbsencesController.text),
      classSchedules: classSchedules,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop();
      SnackBarHelper.showSuccess(context, 'Matéria criada com sucesso!');
    } else {
      SnackBarHelper.showError(
        context,
        provider.error ?? 'Erro ao criar matéria',
      );
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
      clipBehavior: Clip.hardEdge,
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
                      icon: Icons.school,
                      title: 'Nova Matéria',
                      subtitle: 'Preencha todos os campos',
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
                scrollDirection: Axis.vertical,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: DialogTextField(
                          labelText: 'Nome da Matéria',
                          hintText: 'Ex: Circuitos Digitais, Cálculo I...',
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          validator: ValidationHelper.validateSubjectName,
                          enabled: !_isSubmitting,
                          textCapitalization: TextCapitalization.words,
                          onFieldSubmitted: (_) => _maxAbsencesFocusNode.requestFocus(),
                        ),
                      ),
                      const SizedBox(height: DesignConstants.md),
                      SizedBox(
                        width: double.infinity,
                        child: DialogTextField(
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
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: (_isSubmitting || !_isFormValid)
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
                              : const Icon(Icons.add, color: Colors.black),
                          label: Text(
                            _isSubmitting ? 'Criando...' : 'Criar Matéria',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}