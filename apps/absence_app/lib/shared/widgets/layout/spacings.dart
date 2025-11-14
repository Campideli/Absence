import 'package:flutter/material.dart';
import 'package:absence_app/core/theme/app_decorations.dart';

/// Espaçamento vertical padrão entre seções
class SectionSpacing extends StatelessWidget {
  final double? height;
  const SectionSpacing({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height ?? AppDecorations.sectionSpacing.height);
  }
}

/// Espaçamento vertical pequeno
class SmallSpacing extends StatelessWidget {
  final double? height;
  const SmallSpacing({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height ?? AppDecorations.smallSpacing.height);
  }
}

/// Espaçamento vertical para texto
class TextSpacing extends StatelessWidget {
  final double? height;
  const TextSpacing({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height ?? AppDecorations.textSpacing.height);
  }
}

/// Espaçamento vertical para elementos
class ElementSpacing extends StatelessWidget {
  final double? height;
  const ElementSpacing({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height ?? AppDecorations.elementSpacing.height);
  }
}
