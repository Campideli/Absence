import 'package:absence_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:absence_app/features/auth/presentation/widgets/auth_validators.dart';
import 'package:absence_app/shared/widgets/common/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class ForgotPasswordPage extends StatefulWidget {
  final String? initialEmail;
  
  const ForgotPasswordPage({
    super.key,
    this.initialEmail,
  });

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  bool _emailSent = false;
  Timer? _resendTimer;
  int _resendCountdown = 0;
  bool get _canResend => _resendCountdown == 0;

  @override
  void initState() {
    super.initState();
    // Preenche o email inicial se fornecido
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
      // Foca o campo de email após preencher para permitir edição fácil
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _emailFocusNode.requestFocus();
        // Move cursor para o final do texto
        _emailController.selection = TextSelection.fromPosition(
          TextPosition(offset: _emailController.text.length),
        );
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _handleSendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      
      if (mounted) {
        // Se não houve erro, mostrar tela de sucesso
        if (authProvider.error == null) {
          setState(() {
            _emailSent = true;
          });
          _startResendTimer();
        }
        // Se houve erro, manter na tela de formulário e mostrar o erro
      }
    }
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 300; // 5 minutos ao invés de 15 segundos
    });
    
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
          } else {
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _handleResendEmail() async {
    if (_canResend) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      
      if (mounted) {
        // Se não houve erro, reiniciar timer
        if (authProvider.error == null) {
          _startResendTimer();
        }
        // Se houve erro, não reiniciar o timer (deixar o usuário tentar novamente)
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                authProvider.clearError();
                Navigator.of(context).pop();
              },
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 1),
                    
                    if (!_emailSent) ...[
                      Text(
                        'Esqueceu sua senha?',
                        textAlign: TextAlign.center,
                        style: textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Digite seu email e enviaremos um link para redefinir sua senha.',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ] else ...[
                      Icon(
                        Icons.mark_email_read_outlined,
                        size: 80,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Email enviado!',
                        textAlign: TextAlign.center,
                        style: textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Verifique sua caixa de entrada, spam ou lixo eletrônico e siga as instruções para redefinir sua senha.',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Email: ${_emailController.text.trim()}',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],

                    const Spacer(flex: 2),

                    if (!_emailSent) ...[
                      ErrorMessage(message: authProvider.error),

                      CustomTextField(
                        labelText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        validator: AuthValidators.validateEmail,
                        onFieldSubmitted: (_) {
                          _handleSendResetEmail();
                        },
                      ),

                      const SizedBox(height: 24),
                      AppButton.primary(
                        text: authProvider.isPasswordResetLoading 
                            ? 'Enviando...' 
                            : 'Enviar link de redefinição',
                        onPressed: authProvider.isPasswordResetLoading 
                            ? null 
                            : _handleSendResetEmail,
                        isLoading: authProvider.isPasswordResetLoading,
                      ),
                    ] else ...[
                      AppButton.primary(
                        text: 'Voltar ao login',
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(height: 16),
                      AppButton.text(
                        text: authProvider.isPasswordResetLoading
                            ? 'Reenviando...'
                            : _canResend 
                                ? 'Reenviar email' 
                                : _resendCountdown > 60
                                    ? 'Reenviar email em ${(_resendCountdown / 60).floor()}m ${_resendCountdown % 60}s'
                                    : 'Reenviar email em ${_resendCountdown}s',
                        onPressed: _canResend && !authProvider.isPasswordResetLoading 
                            ? _handleResendEmail 
                            : null,
                        foregroundColor: (_canResend && !authProvider.isPasswordResetLoading)
                            ? null 
                            : colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ],

                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
