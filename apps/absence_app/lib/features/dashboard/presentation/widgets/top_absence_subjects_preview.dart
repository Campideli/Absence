import 'package:flutter/material.dart';
import '../../../../shared/models/subject_model.dart';
import '../../../../core/theme/theme_exports.dart';
import 'circular_absence_progress.dart';
import '../pages/dashboard_page.dart';
import '../../../../core/constants/design_constants.dart';

class TopAbsenceSubjectsPreview extends StatefulWidget {
  final List<SubjectModel> subjects;
  const TopAbsenceSubjectsPreview({super.key, required this.subjects});

  @override
  State<TopAbsenceSubjectsPreview> createState() => _TopAbsenceSubjectsPreviewState();
}

class _TopAbsenceSubjectsPreviewState extends State<TopAbsenceSubjectsPreview> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final subjects = widget.subjects;
    if (subjects.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      return Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignConstants.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Próximas do limite', style: AppTextStyles.sectionTitle(context)),
              const SizedBox(height: 15),
              SizedBox(
                height: 140,
                child: Center(
                  child: Text(
                    'Nenhuma matéria cadastrada ainda.\nAdicione matérias para acompanhar suas faltas.',
                    style: AppTextStyles.bodyText(context).copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final colorScheme = Theme.of(context).colorScheme;
    final topSubjects = subjects
        .where((s) => s.maxAbsences > 0)
        .toList()
      ..sort((a, b) => ((b.currentAbsences / b.maxAbsences).compareTo(a.currentAbsences / a.maxAbsences)));

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(DesignConstants.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignConstants.radiusMd),
        onTap: () {
          final dashboardState = context.findAncestorStateOfType<DashboardPageState>();
          if (dashboardState != null) {
            dashboardState.setCurrentIndex(2); // 2 = aba de faltas
          }
        },
        onHover: (hovering) => setState(() => _hovering = hovering),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Próximas do limite', style: AppTextStyles.sectionTitle(context)),
              const SizedBox(height: 15),
              SizedBox(
                height: 140,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: topSubjects.take(3).map((subject) {
                    final percent = subject.maxAbsences > 0
                        ? (subject.currentAbsences / subject.maxAbsences).clamp(0.0, 1.0)
                        : 0.0;
                    Color progressColor;
                    if (percent >= DesignConstants.progressThresholdDanger / 100) {
                      progressColor = Colors.redAccent;
                    } else if (percent >= DesignConstants.progressThresholdWarning / 100) {
                      progressColor = Colors.orangeAccent;
                    } else {
                      progressColor = Colors.greenAccent.shade400;
                    }
                    // Cards reagem ao hover externo
          final cardBorderColor = _hovering
            ? progressColor.withValues(alpha: 180 / 255)
            : progressColor.withValues(alpha: 100 / 255);
                    final cardBoxShadow = _hovering
                        ? [
                            BoxShadow(
                              color: progressColor.withValues(alpha: 40 / 255), // menos intenso
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                            BoxShadow(
                              color: colorScheme.onSurface.withValues(alpha: 10 / 255),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: progressColor.withValues(alpha: 24 / 255),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: colorScheme.onSurface.withValues(alpha: 8 / 255),
                              blurRadius: 1,
                              offset: const Offset(0, 1),
                            ),
                          ];
          final cardBgColor = _hovering
            ? colorScheme.surface.withValues(alpha: 0.992)
            : colorScheme.surface;
                    return Flexible(
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutBack,
                        tween: Tween<double>(begin: 0.95, end: 1.0),
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(DesignConstants.radiusLg),
                                boxShadow: cardBoxShadow,
                                border: Border.all(
                                  color: cardBorderColor,
                                  width: 2.2,
                                ),
                                color: cardBgColor,
                              ),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 6),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularAbsenceProgress(
                                        percent: percent,
                                        current: subject.currentAbsences,
                                        max: subject.maxAbsences,
                                        color: progressColor,
                                        size: 54,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        subject.name,
                                        style: AppTextStyles.bodyText(context).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
