import 'package:flutter/material.dart';
import 'package:absence_app/core/constants/design_constants.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: DesignConstants.buttonVertical),
          shape: RoundedRectangleBorder(
            borderRadius: DesignConstants.borderRadiusMd,
          ),
          side: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.3),
            width: 1,
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: colorScheme.onSurface,
        ),
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.onSurface,
                  ),
                ),
              )
            : Image.asset(
                'assets/images/google_logo.png',
                height: 20,
                width: 20,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback: usar ícone do Material se a imagem não for encontrada
                  return Icon(
                    Icons.g_mobiledata,
                    size: 24,
                    color: colorScheme.onSurface,
                  );
                },
              ),
        label: Text(
          'Continuar com Google',
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
