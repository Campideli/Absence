import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppThemes {
  /// Tema escuro da aplicação
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.black,  // Texto preto sobre fundo branco
        secondary: AppColors.secondary,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        surfaceContainerHighest: AppColors.darkBackground,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      snackBarTheme: const SnackBarThemeData(
        contentTextStyle: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom().copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) {
                return Colors.black.withValues(alpha: 0.15);
              }
              if (states.contains(WidgetState.hovered)) {
                return Colors.black.withValues(alpha: 0.08);
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  /// Tema claro da aplicação
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.black,  // Texto preto sobre fundo branco
        secondary: AppColors.secondary,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
        surfaceContainerHighest: AppColors.lightBackground,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      snackBarTheme: const SnackBarThemeData(
        contentTextStyle: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom().copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) {
                return Colors.black.withValues(alpha: 0.15);
              }
              if (states.contains(WidgetState.hovered)) {
                return Colors.black.withValues(alpha: 0.08);
              }
              return null;
            },
          ),
        ),
      ),
    );
  }
}
