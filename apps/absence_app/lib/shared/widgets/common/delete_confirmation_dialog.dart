import 'package:flutter/material.dart';
import '../buttons/dialog_action_buttons.dart';
import 'dialog_header.dart';

/// Dialog de confirmação genérico para ações destrutivas
class DeleteConfirmationDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmText;
  final Future<void> Function() onConfirm;

  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Excluir',
    required this.onConfirm,
  });

  @override
  State<DeleteConfirmationDialog> createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> {
  bool _isDeleting = false;

  Future<void> _handleConfirm() async {
    setState(() => _isDeleting = true);
    
    try {
      await widget.onConfirm();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DialogHeader(
              icon: Icons.warning_amber_rounded,
              title: widget.title,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              widget.message,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            
            const SizedBox(height: 24),
            
            DialogActionButtons(
              onCancel: _isDeleting ? null : () => Navigator.of(context).pop(false),
              onConfirm: _isDeleting ? null : _handleConfirm,
              confirmText: widget.confirmText,
              confirmIcon: Icons.delete,
              isLoading: _isDeleting,
            ),
          ],
        ),
      ),
    );
  }
}
