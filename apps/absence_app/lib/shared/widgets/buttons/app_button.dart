import 'package:flutter/material.dart';
import '../../../core/constants/design_constants.dart';

/// Enum para diferentes variantes de botão
enum ButtonVariant {
  primary,
  secondary,
  outline,
  text,
  icon,
}

/// Enum para diferentes tamanhos de botão
enum ButtonSize {
  small,
  medium,
  large,
}

/// Widget de botão unificado que suporta diferentes variantes e tamanhos
class AppButton extends StatelessWidget {
  final String? text;
  final Widget? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final ButtonSize size;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderSide? borderSide;
  final TextAlign? textAlign;
  final FontWeight? fontWeight;

  const AppButton({
    super.key,
    this.text,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.width,
    this.padding,
    this.backgroundColor,
    this.foregroundColor,
    this.borderSide,
    this.textAlign,
    this.fontWeight,
  }) : assert(text != null || icon != null, 'Either text or icon must be provided');

  /// Factory constructors para facilitar o uso
  
  /// Botão preenchido (filled) com ícone e texto
  /// Equivalente ao FilledButton.icon do Material 3
  factory AppButton.filled({
    Key? key,
    required String text,
    required IconData iconData,
    VoidCallback? onPressed,
    bool isLoading = false,
    ButtonSize size = ButtonSize.medium,
    double? width,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return AppButton(
      key: key,
      text: text,
      icon: Icon(iconData),
      onPressed: onPressed,
      isLoading: isLoading,
      variant: ButtonVariant.primary,
      size: size,
      width: width,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor ?? Colors.white,
    );
  }
  
  /// Botão primário
  factory AppButton.primary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    ButtonSize size = ButtonSize.medium,
    double? width,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    Color? foregroundColor,
    BorderSide? borderSide,
    Widget? icon,
  }) {
    return AppButton(
      key: key,
      text: text,
      icon: icon,
      onPressed: onPressed,
      isLoading: isLoading,
      variant: ButtonVariant.primary,
      size: size,
      width: width,
      padding: padding,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      borderSide: borderSide,
    );
  }

  /// Botão de texto
  factory AppButton.text({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    TextAlign? textAlign,
    FontWeight? fontWeight,
    Color? foregroundColor,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: ButtonVariant.text,
      size: size,
      textAlign: textAlign,
      fontWeight: fontWeight,
      foregroundColor: foregroundColor,
    );
  }

  /// Botão outline
  factory AppButton.outline({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    ButtonSize size = ButtonSize.medium,
    double? width,
    Widget? icon,
    Color? borderColor,
    Color? foregroundColor,
  }) {
    return AppButton(
      key: key,
      text: text,
      icon: icon,
      onPressed: onPressed,
      isLoading: isLoading,
      variant: ButtonVariant.outline,
      size: size,
      width: width,
      borderSide: borderColor != null ? BorderSide(color: borderColor) : null,
      foregroundColor: foregroundColor,
    );
  }

  /// Botão apenas com ícone
  factory AppButton.icon({
    Key? key,
    required Widget icon,
    VoidCallback? onPressed,
    bool isLoading = false,
    ButtonSize size = ButtonSize.medium,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return AppButton(
      key: key,
      icon: icon,
      onPressed: onPressed,
      isLoading: isLoading,
      variant: ButtonVariant.icon,
      size: size,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    switch (variant) {
      case ButtonVariant.primary:
        return _buildPrimaryButton(context, colorScheme, textTheme);
      case ButtonVariant.secondary:
        return _buildSecondaryButton(context, colorScheme, textTheme);
      case ButtonVariant.outline:
        return _buildOutlineButton(context, colorScheme, textTheme);
      case ButtonVariant.text:
        return _buildTextButton(context, colorScheme, textTheme);
      case ButtonVariant.icon:
        return _buildIconButton(context, colorScheme);
    }
  }

  Widget _buildPrimaryButton(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return SizedBox(
      width: width ?? double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? colorScheme.onSurface,
          foregroundColor: foregroundColor ?? colorScheme.surface,
          padding: padding ?? EdgeInsets.symmetric(vertical: _getVerticalPadding()),
          shape: RoundedRectangleBorder(
            borderRadius: DesignConstants.borderRadiusMd,
            side: borderSide ?? BorderSide.none,
          ),
          elevation: 0,
          minimumSize: Size(double.infinity, _getButtonHeight()),
          overlayColor: (foregroundColor ?? colorScheme.surface).withValues(alpha: 0.1),
        ),
        onPressed: isLoading ? null : onPressed,
        child: _buildButtonContent(colorScheme, textTheme, colorScheme.surface),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return SizedBox(
      width: width ?? double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? colorScheme.secondary,
          foregroundColor: foregroundColor ?? colorScheme.onSecondary,
          padding: padding ?? EdgeInsets.symmetric(vertical: _getVerticalPadding()),
          shape: RoundedRectangleBorder(
            borderRadius: DesignConstants.borderRadiusMd,
            side: borderSide ?? BorderSide.none,
          ),
          elevation: 0,
          minimumSize: Size(double.infinity, _getButtonHeight()),
        ),
        onPressed: isLoading ? null : onPressed,
        child: _buildButtonContent(colorScheme, textTheme, foregroundColor ?? colorScheme.onSecondary),
      ),
    );
  }

  Widget _buildOutlineButton(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return SizedBox(
      width: width ?? double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: padding ?? EdgeInsets.symmetric(vertical: _getVerticalPadding()),
          shape: RoundedRectangleBorder(
            borderRadius: DesignConstants.borderRadiusMd,
          ),
          side: borderSide ?? BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.3),
            width: 1,
          ),
          backgroundColor: backgroundColor ?? Colors.transparent,
          foregroundColor: foregroundColor ?? colorScheme.onSurface,
          minimumSize: Size(double.infinity, _getButtonHeight()),
        ),
        onPressed: isLoading ? null : onPressed,
        child: _buildButtonContent(colorScheme, textTheme, foregroundColor ?? colorScheme.onSurface),
      ),
    );
  }

  Widget _buildTextButton(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    Widget button = TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: padding ?? EdgeInsets.symmetric(horizontal: DesignConstants.sm),
        overlayColor: (foregroundColor ?? colorScheme.onSurface).withValues(alpha: 0.1),
      ),
      child: Text(
        text!,
        style: _getTextStyle(textTheme)?.copyWith(
          color: foregroundColor ?? colorScheme.onSurface,
          fontWeight: fontWeight ?? FontWeight.w500,
        ),
      ),
    );

    if (textAlign != null) {
      Alignment alignment;
      switch (textAlign) {
        case TextAlign.left:
          alignment = Alignment.centerLeft;
          break;
        case TextAlign.right:
          alignment = Alignment.centerRight;
          break;
        default:
          alignment = Alignment.center;
      }
      
      return Align(
        alignment: alignment,
        child: button,
      );
    }

    return button;
  }

  Widget _buildIconButton(BuildContext context, ColorScheme colorScheme) {
    return IconButton(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: _getIconSize(),
              height: _getIconSize(),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  foregroundColor ?? colorScheme.onSurface,
                ),
              ),
            )
          : icon!,
      iconSize: _getIconSize(),
      color: foregroundColor ?? colorScheme.onSurface,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        minimumSize: Size(_getButtonHeight(), _getButtonHeight()),
      ),
    );
  }

  Widget _buildButtonContent(ColorScheme colorScheme, TextTheme textTheme, Color textColor) {
    if (isLoading) {
      return SizedBox(
        height: _getLoadingIndicatorSize(),
        width: _getLoadingIndicatorSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (text != null && icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          SizedBox(width: DesignConstants.sm),
          Text(
            text!,
            style: _getTextStyle(textTheme)?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      );
    }

    if (text != null) {
      return Text(
        text!,
        style: _getTextStyle(textTheme)?.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      );
    }

    return icon!;
  }

  double _getButtonHeight() {
    switch (size) {
      case ButtonSize.small:
        return 36.0;
      case ButtonSize.medium:
        return 48.0;
      case ButtonSize.large:
        return 56.0;
    }
  }

  double _getVerticalPadding() {
    switch (size) {
      case ButtonSize.small:
        return 8.0;
      case ButtonSize.medium:
        return DesignConstants.buttonVertical;
      case ButtonSize.large:
        return 20.0;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 18.0;
      case ButtonSize.medium:
        return 24.0;
      case ButtonSize.large:
        return 28.0;
    }
  }

  double _getLoadingIndicatorSize() {
    switch (size) {
      case ButtonSize.small:
        return 16.0;
      case ButtonSize.medium:
        return 20.0;
      case ButtonSize.large:
        return 24.0;
    }
  }

  TextStyle? _getTextStyle(TextTheme textTheme) {
    switch (size) {
      case ButtonSize.small:
        return textTheme.bodyMedium;
      case ButtonSize.medium:
        return textTheme.bodyLarge;
      case ButtonSize.large:
        return textTheme.titleMedium;
    }
  }
}
