import 'package:flutter/material.dart';
import 'package:absence_app/core/constants/design_constants.dart';

class ErrorMessage extends StatelessWidget {
  final String? message;

  const ErrorMessage({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: DesignConstants.sm,
        horizontal: DesignConstants.md,
      ),
      margin: const EdgeInsets.only(bottom: DesignConstants.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: DesignConstants.borderRadiusSm,
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        message!,
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.error,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
