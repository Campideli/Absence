import 'package:flutter/material.dart';
import 'package:absence_app/features/settings/presentation/pages/settings_page.dart';

/// Classe que centraliza todas as decorações e elementos visuais do app
/// seguindo exatamente o padrão das páginas de login/registro
/// usando apenas cores neutras (cinza/branco)
class AppDecorations {
  
  /// AppBar transparente padrão usado em todas as páginas
  static AppBar transparentAppBar({
    required String title,
    required BuildContext context,
    List<Widget>? actions,
    Widget? leading,
    bool showLogoutButton = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Adicionar botão de configurações às actions
    final List<Widget> finalActions = [
      ...(actions ?? []),
      IconButton(
        icon: const Icon(Icons.settings),
        tooltip: 'Configurações',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SettingsPage(),
            ),
          );
        },
      ),
    ];
// Import necessário para SettingsPage
    
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      leading: leading,
      actions: finalActions.isNotEmpty ? finalActions : null,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
    );
  }

  /// Container para cabeçalhos de seção com estatísticas
  static Container sectionHeader({
    required Widget child,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: child,
    );
  }

  /// Container para seções de conteúdo vazio (empty states)
  static Container emptyStateContainer({
    required Widget child,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: child,
    );
  }

  /// Badge neutro para contadores e estatísticas
  static Container badge({
    required Widget child,
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  /// Container minimalista para mensagens e estados
  static Container simpleContainer({
    required Widget child,
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  /// Padding padrão para páginas (igual ao login)
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 24.0);
  
  /// Largura máxima para conteúdo centralizado e responsivo
  static const double maxContentWidth = 600.0;
  
  /// Container centralizado e responsivo para páginas
  /// Usa maxWidth para limitar largura em telas grandes
  static Widget responsiveContainer({
    required Widget child,
    double? maxWidth,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? maxContentWidth,
        ),
        child: child,
      ),
    );
  }
  
  /// Espaçamento entre seções principais
  static const SizedBox sectionSpacing = SizedBox(height: 32);
  
  /// Espaçamento entre elementos relacionados
  static const SizedBox elementSpacing = SizedBox(height: 16);
  
  /// Espaçamento entre textos
  static const SizedBox textSpacing = SizedBox(height: 8);
  
  /// Espaçamento pequeno (igual ao login)
  static const SizedBox smallSpacing = SizedBox(height: 4);

  /// Ícone neutro para estados vazios (sem cores específicas)
  static Widget emptyStateIcon({
    required IconData icon,
    required BuildContext context,
    double size = 80,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Icon(
      icon,
      size: size,
      color: colorScheme.onSurface.withValues(alpha: 0.3),
    );
  }

  /// Ícone neutro para seções
  static Widget sectionIcon({
    required IconData icon,
    required BuildContext context,
    double size = 24,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Icon(
      icon,
      color: colorScheme.onSurface.withValues(alpha: 0.6),
      size: size,
    );
  }

  /// Row padrão para estatísticas de seção (sem cores específicas)
  static Widget statRow({
    required IconData icon,
    required String text,
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          icon, 
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// ListView com padding padrão
  static Widget paddedListView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    EdgeInsets? padding,
  }) {
    return ListView.builder(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }

  /// Container para mensagens neutras (sem cores específicas)
  static Widget neutralMessageContainer({
    required Widget child,
    required BuildContext context,
  }) {
    return simpleContainer(child: child, context: context);
  }
}
