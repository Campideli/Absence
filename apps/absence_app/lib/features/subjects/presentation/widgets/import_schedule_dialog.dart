import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../shared/widgets/layout/spacings.dart';
import '../../../../core/constants/design_constants.dart';
import '../../../../shared/widgets/common/dialog_header.dart';
import '../../../../shared/widgets/buttons/dialog_action_buttons.dart';
import '../../data/schedule_import_service.dart';

enum Semester { first, second }

class ImportScheduleDialog extends StatefulWidget {
  const ImportScheduleDialog({super.key});

  @override
  State<ImportScheduleDialog> createState() => _ImportScheduleDialogState();
}

class _ImportScheduleDialogState extends State<ImportScheduleDialog> {
  final ScheduleImportService _importService = ScheduleImportService();
  
  String? _selectedFileName;
  List<int>? _selectedFileBytes;
  bool _isImporting = false;
  String? _fileError;
  List<ImportedSubject>? _allImportedSubjects;
  Semester _selectedSemester = Semester.first;
  final Set<String> _removedSubjectIds = {};

  @override
  void dispose() {
    super.dispose();
  }

  void _close() {
    if (!_isImporting) Navigator.of(context).pop();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        setState(() {
          _selectedFileName = file.name;
          _selectedFileBytes = file.bytes;
          _fileError = null;
          _allImportedSubjects = null;
        });
      }
    } catch (e) {
      setState(() {
        _fileError = 'Erro ao selecionar arquivo: $e';
      });
    }
  }

  Future<void> _import() async {
    await _pickFile();
    
    if (_selectedFileName != null && _selectedFileBytes != null) {
      await _processFile();
    }
  }

  Future<void> _processFile() async {
    if (_selectedFileName == null || _selectedFileBytes == null) {
      return;
    }

    setState(() {
      _isImporting = true;
      _fileError = null;
    });
    
    try {
      final subjects = await _importService.importFromPdf(
        _selectedFileBytes!,
        _selectedFileName!,
      );
      
      if (mounted) {
        setState(() {
          _allImportedSubjects = subjects;
          _isImporting = false;
        });
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _fileError = 'Erro ao importar: ${e.toString()}';
          _isImporting = false;
          _allImportedSubjects = null;
        });
      }
    }
  }

  List<ImportedSubject> get _filteredSubjects {
    if (_allImportedSubjects == null) return [];
    
    List<ImportedSubject> filtered;
    if (_selectedSemester == Semester.first) {
      // Semester 1: show subjects with "1" OR without "2" (includes annual "A")
      filtered = _allImportedSubjects!.where((subject) {
        final tp = subject.tp.toUpperCase();
        return tp.contains('1') || !tp.contains('2');
      }).toList();
    } else {
      // Semester 2: show only subjects with "2"
      filtered = _allImportedSubjects!.where((subject) {
        return subject.tp.toUpperCase().contains('2');
      }).toList();
    }
    
    // Remove subjects marked for deletion using unique ID
    return filtered.where((subject) {
      final subjectId = '${subject.name}_${subject.maxAbsences}';
      return !_removedSubjectIds.contains(subjectId);
    }).toList();
  }

  void _removeSubject(ImportedSubject subject) {
    setState(() {
      final subjectId = '${subject.name}_${subject.maxAbsences}';
      _removedSubjectIds.add(subjectId);
    });
  }

  Future<void> _save() async {
    final filtered = _filteredSubjects;
    if (filtered.isEmpty) {
      setState(() => _fileError = 'Nenhuma matéria para salvar');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _fileError = 'Usuário não autenticado');
      return;
    }

    // Convert to SubjectModel list
    final subjects = filtered.map((s) => s.toSubjectModel(user.uid)).toList();

    if (mounted) {
      Navigator.of(context).pop(subjects);
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  const Expanded(
                    child: DialogHeader(
                      icon: Icons.file_upload_outlined,
                      title: 'Importar horário',
                      subtitle: 'Arraste o arquivo ou selecione manualmente',
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Fechar',
                    onPressed: _isImporting ? null : _close,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DesignConstants.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Área visual de upload
                  if (_allImportedSubjects == null) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(DesignConstants.radiusMd),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isImporting ? Icons.hourglass_empty : Icons.upload_file,
                            size: 40,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isImporting
                                ? 'Processando arquivo...'
                                : _selectedFileName != null
                                    ? 'Arquivo: $_selectedFileName'
                                    : 'Selecione o arquivo de horários',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          if (_fileError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _fileError!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (!_isImporting) ...[
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _import,
                              icon: const Icon(Icons.folder_open),
                              label: const Text('Selecionar arquivo'),
                            ),
                          ] else ...[
                            const SizedBox(height: 16),
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ] else ...[
                    // Semester selector
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Semestre 1'),
                            selected: _selectedSemester == Semester.first,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedSemester = Semester.first);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Semestre 2'),
                            selected: _selectedSemester == Semester.second,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedSemester = Semester.second);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SectionSpacing(),
                    // Lista de matérias importadas responsiva
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(DesignConstants.radiusMd),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(DesignConstants.md),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(DesignConstants.radiusMd),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row with responsive layout
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isWide = constraints.maxWidth > 400;
                                    if (isWide) {
                                      return Row(
                                        children: [
                                          Icon(Icons.check_circle, color: colorScheme.primary),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${_filteredSubjects.length} matérias encontradas',
                                              style: Theme.of(context).textTheme.titleSmall,
                                            ),
                                          ),
                                          TextButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _allImportedSubjects = null;
                                                _selectedFileName = null;
                                                _selectedFileBytes = null;
                                                _removedSubjectIds.clear();
                                              });
                                            },
                                            icon: const Icon(Icons.refresh, size: 18),
                                            label: const Text('Novo arquivo'),
                                          ),
                                        ],
                                      );
                                    } else {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.check_circle, color: colorScheme.primary),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  '${_filteredSubjects.length} matérias encontradas',
                                                  style: Theme.of(context).textTheme.titleSmall,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          TextButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _allImportedSubjects = null;
                                                _selectedFileName = null;
                                                _selectedFileBytes = null;
                                                _removedSubjectIds.clear();
                                              });
                                            },
                                            icon: const Icon(Icons.refresh, size: 18),
                                            label: const Text('Novo arquivo'),
                                          ),
                                        ],
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: ListView.separated(
                              padding: const EdgeInsets.all(DesignConstants.md),
                              itemCount: _filteredSubjects.length,
                              separatorBuilder: (context, index) => const SizedBox(height: DesignConstants.sm),
                              itemBuilder: (context, index) {
                                final subject = _filteredSubjects[index];
                                return Card(
                                  elevation: 0,
                                  color: colorScheme.surfaceContainerHighest,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(DesignConstants.radiusSm),
                                    side: BorderSide(
                                      color: colorScheme.outline.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(DesignConstants.md),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                subject.name,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Máximo de faltas: ${subject.maxAbsences}',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: colorScheme.error,
                                          ),
                                          tooltip: 'Remover matéria',
                                          onPressed: () => _removeSubject(subject),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SectionSpacing(),
                  DialogActionButtons(
                    onCancel: _isImporting ? null : _close,
                    onConfirm: _filteredSubjects.isNotEmpty && !_isImporting ? _save : null,
                    confirmText: 'Salvar matérias',
                    confirmIcon: Icons.save,
                    isLoading: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
