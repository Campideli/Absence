import 'package:flutter/material.dart';
import 'package:absence_app/core/constants/design_constants.dart';

class CustomTextField extends StatefulWidget {
  final String labelText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final void Function(String)? onFieldSubmitted;

  const CustomTextField({
    super.key,
    required this.labelText,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.onFieldSubmitted,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  String? _errorText;
  bool _hasInteracted = false;

  // Método público para limpar erros (pode ser usado externamente se necessário)
  void clearError() {
    if (_errorText != null) {
      setState(() {
        _errorText = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Escutar mudanças no controller para validação em tempo real
    widget.controller?.addListener(_onTextChanged);
    widget.focusNode?.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onTextChanged);
    widget.focusNode?.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onTextChanged() {
    // Marcar como interagido quando usuário digita
    if (!_hasInteracted) {
      setState(() {
        _hasInteracted = true;
      });
    }
    
    // Validar em tempo real durante a digitação
    if (widget.validator != null) {
      final error = widget.validator?.call(widget.controller?.text);
      if (_errorText != error) {
        setState(() {
          _errorText = error;
        });
      }
    }
  }

  void _onFocusChanged() {
    if (widget.focusNode?.hasFocus == true) {
      setState(() {
        _hasInteracted = true;
      });
    } else {
      // Quando perde o foco, valida o campo
      if (widget.validator != null) {
        final error = widget.validator?.call(widget.controller?.text);
        if (_errorText != error) {
          setState(() {
            _errorText = error;
          });
        }
      }
    }
  }

  String? _validateField(String? value) {
    // Esta função é chamada pelo FormField principalmente para validação no submit
    final error = widget.validator?.call(value);
    
    // Garantir que está marcado como interagido
    if (!_hasInteracted) {
      _hasInteracted = true;
    }
    
    // Atualizar o estado do erro se necessário
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _errorText != error) {
        setState(() {
          _errorText = error;
        });
      }
    });
    
    return error;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasError = _errorText != null && _hasInteracted;

    return TextFormField(
      controller: widget.controller,
      validator: _validateField,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      focusNode: widget.focusNode,
      onFieldSubmitted: widget.onFieldSubmitted,
      cursorColor: hasError ? colorScheme.error : colorScheme.onSurface,
      style: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: 0.87),
      ),
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: TextStyle(
          color: hasError 
            ? colorScheme.error.withValues(alpha: 0.8)
            : colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        errorText: _hasInteracted ? _errorText : null,
        border: OutlineInputBorder(
          borderRadius: DesignConstants.borderRadiusMd,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: DesignConstants.borderRadiusMd,
          borderSide: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.23),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DesignConstants.borderRadiusMd,
          borderSide: BorderSide(
            color: colorScheme.onSurface,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: DesignConstants.borderRadiusMd,
          borderSide: BorderSide(
            color: colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: DesignConstants.borderRadiusMd,
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignConstants.md,
          vertical: DesignConstants.buttonVertical,
        ),
      ),
    );
  }
}
