import 'package:flutter/material.dart';

/// Botões de ação para dialogs (Cancelar/Confirmar)
class DialogActionButtons extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final String confirmText;
  final IconData confirmIcon;
  final bool isLoading;

  const DialogActionButtons({
    super.key,
    this.onCancel,
    this.onConfirm,
    this.confirmText = 'Confirmar',
    this.confirmIcon = Icons.check,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Botão Confirmar
        FilledButton.icon(
          onPressed: isLoading ? null : onConfirm,
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(confirmIcon, color: Colors.black),
          label: Text(
            isLoading ? 'Processando...' : confirmText,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
