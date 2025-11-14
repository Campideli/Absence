import 'package:absence_app/features/auth/presentation/widgets/auth_validators.dart';
import 'package:absence_app/shared/widgets/buttons/primary_action_button.dart';
import 'package:flutter/material.dart';

import 'package:absence_app/shared/widgets/form_fields/custom_text_field.dart';
import 'package:absence_app/core/constants/design_constants.dart';
import 'package:absence_app/shared/widgets/common/dialog_header.dart';
import 'package:absence_app/shared/widgets/layout/spacings.dart';

/// Dialog padrão para alteração de senha do usuário
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  @override
  void initState() {
    super.initState();
      // Listeners removidos: validação agora é feita apenas via validator
  }
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  // Senha sempre oculta, sem opção de visibilidade

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final newPass = _newPasswordController.text.trim();
    if (mounted) {
      Navigator.of(context).pop({
        'newPassword': newPass,
      });
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: colorScheme.surface,
      contentPadding: EdgeInsets.zero,
      titlePadding: EdgeInsets.zero,
      actionsPadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(DesignConstants.lg),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DesignConstants.radiusLg),
          ),
        ),
        child: Row(
          children: [
            const Expanded(
              child: DialogHeader(
                icon: Icons.lock_outline,
                title: 'Alterar senha',
                subtitle: null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Fechar',
              onPressed: () => Navigator.of(context).pop(),
              color: Colors.white,
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: DesignConstants.dialogWidthSmall,
        child: Padding(
          padding: const EdgeInsets.all(DesignConstants.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  labelText: 'Nova senha',
                  controller: _newPasswordController,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  onFieldSubmitted: (_) => _submit(),
                  validator: AuthValidators.validatePassword,
                ),
                const ElementSpacing(),
                CustomTextField(
                  labelText: 'Confirmar nova senha',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) => AuthValidators.validatePasswordConfirmation(
                    value,
                    _newPasswordController.text,
                  ),
                ),
                const SectionSpacing(),
                SizedBox(
                  width: 100,
                  child: PrimaryActionButton(
                    label: _isSubmitting ? 'Salvando...' : 'Salvar',
                    icon: Icons.check,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: const [],
    );
  }
}
