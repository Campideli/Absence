import 'package:flutter/material.dart';

/// Constantes de design unificadas da aplicação
class DesignConstants {
  const DesignConstants._();

  // =====================
  // SPACING CONSTANTS
  // =====================
  
  /// Espaçamentos básicos
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  /// Espaçamentos específicos para componentes
  static const double buttonVertical = 16.0;
  static const double cardPadding = 16.0;
  static const double screenPadding = 24.0;
  static const double listItemSpacing = 12.0;
  static const double formFieldSpacing = 16.0;
  static const double formSectionSpacing = 32.0;

  // =====================
  // RADIUS CONSTANTS
  // =====================
  
  /// Valores de raio
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 28.0;
  static const double radiusFull = 999.0;

  /// BorderRadius pré-definidos
  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderRadiusXxl = BorderRadius.all(Radius.circular(radiusXxl));
  static const BorderRadius borderRadiusFull = BorderRadius.all(Radius.circular(radiusFull));

  // =====================
  // DIALOG CONSTANTS
  // =====================
  
  /// Larguras de dialogs
  static const double dialogWidthSmall = 400.0;
  static const double dialogWidthMedium = 500.0;
  static const double dialogWidthLarge = 600.0;

  // =====================
  // COMPONENT SIZES
  // =====================
  
  /// Tamanhos de chips de dia
  static const double dayChipWidth = 60.0;
  static const double dayChipHeight = 72.0;

  /// Tamanhos de ícones
  static const double iconSizeSmall = 18.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 28.0;
  static const double iconSizeXLarge = 32.0;

  // =====================
  // PROGRESS THRESHOLDS
  // =====================
  
  /// Thresholds de porcentagem para indicadores de progresso
  static const double progressThresholdWarning = 50.0;
  static const double progressThresholdDanger = 80.0;
}
