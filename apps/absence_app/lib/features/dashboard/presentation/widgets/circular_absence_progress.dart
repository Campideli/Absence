import 'package:flutter/material.dart';

class CircularAbsenceProgress extends StatelessWidget {
  final double percent; // 0.0 a 1.0
  final int current;
  final int max;
  final Color color;
  final double size;
  const CircularAbsenceProgress({
    super.key,
    required this.percent,
    required this.current,
    required this.max,
    required this.color,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
  final bgColor = Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(60);
    // Determina cor do texto (branco para barras escuras, preto para barras claras)
  // (cor do texto já definida como branco abaixo)
    final percentValue = (max > 0) ? (current / max).clamp(0.0, 1.0) : 0.0;
    final percentText = '${(percentValue * 100).toStringAsFixed(0)}%';
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 7,
            valueColor: AlwaysStoppedAnimation<Color>(bgColor),
          ),
          CircularProgressIndicator(
            value: percentValue,
            strokeWidth: 7,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            backgroundColor: Colors.transparent,
          ),
          Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              percentText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.white,
                letterSpacing: -1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
