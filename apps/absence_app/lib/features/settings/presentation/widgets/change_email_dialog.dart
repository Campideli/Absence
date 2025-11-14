import 'package:absence_app/shared/widgets/buttons/primary_action_button.dart';
import 'package:flutter/material.dart';
import 'package:absence_app/shared/widgets/form_fields/dialog_text_field.dart';
import 'package:absence_app/core/constants/design_constants.dart';
import 'package:absence_app/shared/widgets/common/dialog_header.dart';
import 'package:absence_app/shared/widgets/layout/spacings.dart';

/// Dialog padrão para alteração de email do usuário
class ChangeEmailDialog extends StatefulWidget {
  final String initialEmail;
  const ChangeEmailDialog({super.key, required this.initialEmail});

  @override
  State<ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<ChangeEmailDialog> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            Expanded(
              child: DialogHeader(
                icon: Icons.email_outlined,
                title: 'Alterar email',
                subtitle: null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Fechar',
              onPressed: () => Navigator.of(context).pop(),
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: DesignConstants.dialogWidthSmall,
        child: Padding(
          padding: const EdgeInsets.all(DesignConstants.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DialogTextField(
                labelText: 'Novo email',
                controller: _controller,
                keyboardType: TextInputType.emailAddress,
                errorText: _errorText,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SectionSpacing(),
              SizedBox(
                width: 100,
                child: PrimaryActionButton(
                  label: 'Salvar',
                  icon: Icons.check,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: const [],
    );
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty || !value.contains('@')) {
      setState(() => _errorText = 'Digite um email válido');
      return;
    }
    Navigator.of(context).pop(value);
  }
}
