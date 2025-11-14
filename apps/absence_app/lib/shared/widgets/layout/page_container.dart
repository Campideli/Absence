import 'package:flutter/material.dart';
import 'package:absence_app/core/theme/app_decorations.dart';

/// Container padrão para páginas, já aplica padding horizontal e centralização responsiva.
class PageContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Alignment alignment;
  const PageContainer({
    super.key,
    required this.child,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: AppDecorations.responsiveContainer(
        child: Padding(
          padding: padding ?? AppDecorations.pagePadding,
          child: child,
        ),
      ),
    );
  }
}
