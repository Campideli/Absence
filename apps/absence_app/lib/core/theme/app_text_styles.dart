import 'package:flutter/material.dart';

/// Classe que centraliza todos os estilos de texto do app
/// seguindo exatamente o padrão das páginas de login/registro
/// usando apenas cores onSurface (cinza/branco)
class AppTextStyles {
  
  /// Títulos de páginas principais (ex: "Absence" no login)
  static TextStyle pageTitle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Theme.of(context).textTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: colorScheme.onSurface,
    ) ?? const TextStyle();
  }

  /// Subtítulos descritivos (ex: "Sua ferramenta de controle acadêmico")
  static TextStyle pageSubtitle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Theme.of(context).textTheme.titleMedium?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.7),
    ) ?? const TextStyle();
  }

  /// Títulos de seções (ex: "Resumo", "Faltas Recentes")
  static TextStyle sectionTitle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: colorScheme.onSurface,
    ) ?? const TextStyle();
  }

  /// Saudações (ex: "Olá, Nome!")
  static TextStyle greeting(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: colorScheme.onSurface,
    ) ?? const TextStyle();
  }

  /// Texto descritivo complementar
  static TextStyle greetingSubtext(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.7),
    ) ?? const TextStyle();
  }

  /// Texto padrão para o corpo de conteúdo
  static TextStyle bodyText(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: colorScheme.onSurface,
    ) ?? const TextStyle();
  }

  /// Texto para estados vazios - título
  static TextStyle emptyStateTitle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: colorScheme.onSurface,
    ) ?? const TextStyle();
  }

  /// Texto para estados vazios - subtítulo
  static TextStyle emptyStateSubtitle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.7),
    ) ?? const TextStyle();
  }

  /// Texto para títulos de erro
  static TextStyle errorTitle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: colorScheme.onSurface,
    ) ?? const TextStyle();
  }

  /// Texto para mensagens de erro
  static TextStyle errorSubtitle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.7),
    ) ?? const TextStyle();
  }

  /// Texto pequeno para badges (mantém padrão neutro)
  static TextStyle badgeText(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Theme.of(context).textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface.withValues(alpha: 0.8),
    ) ?? const TextStyle();
  }
}
