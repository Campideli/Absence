import '../widgets/change_email_dialog.dart';
import '../widgets/change_password_dialog.dart';
import 'package:absence_app/core/theme/app_text_styles.dart';
import 'package:absence_app/shared/widgets/layout/spacings.dart';
import 'package:absence_app/shared/widgets/buttons/primary_action_button.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:absence_app/features/auth/presentation/providers/auth_provider.dart' as app_auth;

/// Tela de configurações principal
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
  final user = FirebaseAuth.instance.currentUser;
  final isGoogleUser = user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Configurações',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Fechar',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Conta', style: AppTextStyles.sectionTitle(context)),
              const ElementSpacing(),
              // Email
              Text('Email', style: AppTextStyles.bodyText(context)),
              const SmallSpacing(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        user?.email ?? '-',
                        style: AppTextStyles.bodyText(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final result = await showDialog<String>(
                          context: context,
                          builder: (context) => ChangeEmailDialog(initialEmail: user?.email ?? ''),
                        );
                        if (!context.mounted) return;
                        if (result != null && result.isNotEmpty && result != user?.email) {
                          try {
                            await user?.verifyBeforeUpdateEmail(result);
                            await user?.reload();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Verifique seu novo email para confirmar a alteração. Confira o spam se não encontrar na caixa de entrada.',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: Colors.white,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            if (!context.mounted) return;
                            String msg = 'Erro ao alterar email';
                            if (e.code == 'requires-recent-login') {
                              msg = 'Por segurança, faça login novamente para alterar o email.';
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  msg,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: Colors.white,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          } catch (_) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Erro ao alterar email.',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: Colors.white,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Alterar email'),
                    ),
                  ],
                ),
              ),
              const ElementSpacing(),
              // Senha
              Text('Senha', style: AppTextStyles.bodyText(context)),
              const SmallSpacing(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '••••••••',
                        style: AppTextStyles.bodyText(context),
                      ),
                    ),
                    TextButton(
                      onPressed: isGoogleUser ? null : () async {
                        final result = await showDialog<Map<String, String>>(
                          context: context,
                          builder: (context) => const ChangePasswordDialog(),
                        );
                        if (!context.mounted) return;
                        if (result != null && result['newPassword'] != null) {
                          final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(child: CircularProgressIndicator()),
                          );
                          try {
                            await authProvider.changePassword(result['newPassword']!);
                            if (!context.mounted) return;
                            Navigator.of(context, rootNavigator: true).pop(); // Remove loading
                            if (authProvider.error == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Senha alterada com sucesso!',
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                                  ),
                                  backgroundColor: Colors.white,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            } else if (authProvider.error == 'Por segurança, faça login novamente para alterar a senha.') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Por segurança, faça login novamente para alterar a senha.',
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                                  ),
                                  backgroundColor: Colors.white,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    authProvider.error!,
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                                  ),
                                  backgroundColor: Colors.white,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          } catch (_) {
                            if (!context.mounted) return;
                            Navigator.of(context, rootNavigator: true).pop(); // Remove loading
                            // Erro já tratado pelo provider
                          }
                        }
                      },
                      child: const Text('Alterar senha'),
                    ),
                  ],
                ),
              ),
              if (isGoogleUser)
                  Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0, right: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Esta conta está conectada via Google, não é possível alterar a senha por aqui.',
                          style: AppTextStyles.bodyText(context).copyWith(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              const SectionSpacing(),
              // Botão de sair
              Center(
                child: SizedBox(
                  width: 220,
                  child: PrimaryActionButton(
                    label: 'Sair',
                    icon: Icons.logout,
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
