import 'package:flutter/material.dart';
import '../../../../shared/models/subject_model.dart';
import '../../../../core/constants/design_constants.dart';

class SubjectAbsenceCard extends StatefulWidget {
  final SubjectModel subject;
  final VoidCallback onAddAbsence;
  final VoidCallback onRemoveAbsence;

  const SubjectAbsenceCard({
    super.key,
    required this.subject,
    required this.onAddAbsence,
    required this.onRemoveAbsence,
  });

  @override
  State<SubjectAbsenceCard> createState() => _SubjectAbsenceCardState();
}

class _SubjectAbsenceCardState extends State<SubjectAbsenceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  String? _previousStatus;
  int? _previousAbsences;
  
  @override
  void initState() {
    super.initState();
    _previousStatus = widget.subject.status;
    _previousAbsences = widget.subject.currentAbsences;
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 0.98)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.98, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_pulseController);
  }
  
  @override
  void didUpdateWidget(SubjectAbsenceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Detecta mudanças e anima com um pequeno delay
    // para evitar animações visíveis atrás de dialogs
    if (_previousAbsences != widget.subject.currentAbsences ||
        _previousStatus != widget.subject.status) {
      
      // Aguarda um frame para garantir que dialog fechou
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _pulseController.forward(from: 0);
          }
        });
      });
      
      _previousAbsences = widget.subject.currentAbsences;
      _previousStatus = widget.subject.status;
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getProgressColor(BuildContext context, double percentage) {
    if (percentage >= DesignConstants.progressThresholdDanger) {
      return Colors.red;
    } else if (percentage >= DesignConstants.progressThresholdWarning) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percentage = widget.subject.absencePercentage;
    final progressColor = _getProgressColor(context, percentage);

    return ScaleTransition(
      scale: _pulseAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          // Sombra sutil baseada no status
          boxShadow: [
            BoxShadow(
              color: progressColor.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: progressColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Nome da matéria
            Text(
              widget.subject.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            
            // Contador de faltas com animação intensa
            Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.elasticOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.elasticOut,
                        ),
                      ),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    '${widget.subject.currentAbsences}/${widget.subject.maxAbsences}',
                    key: ValueKey('${widget.subject.id}-${widget.subject.currentAbsences}'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: progressColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'faltas',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.elasticOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return RotationTransition(
                      turns: Tween<double>(begin: 0.3, end: 0.0).animate(animation),
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.3, end: 1.0).animate(animation),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    key: ValueKey('${widget.subject.id}-${percentage.toStringAsFixed(0)}'),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: progressColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: progressColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Progress bar com animação suave
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: percentage / 100),
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Botões
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.subject.currentAbsences > 0 ? widget.onRemoveAbsence : null,
                    icon: const Icon(Icons.remove, size: 18),
                    label: const Text('Remover'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(
                        color: widget.subject.currentAbsences > 0
                            ? colorScheme.error
                            : colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith<Color?>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.pressed)) {
                            return colorScheme.error.withValues(alpha: 0.15);
                          }
                          if (states.contains(WidgetState.hovered)) {
                            return colorScheme.error.withValues(alpha: 0.08);
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.onAddAbsence,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Adicionar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                        color: Colors.white,
                        width: 1,
                      ),
                      elevation: 0,
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith<Color?>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.pressed)) {
                            return Colors.white.withValues(alpha: 0.15);
                          }
                          if (states.contains(WidgetState.hovered)) {
                            return Colors.white.withValues(alpha: 0.08);
                          }
                          return null;
                        },
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
    );
  }
}
