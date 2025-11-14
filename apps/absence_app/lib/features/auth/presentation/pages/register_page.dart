import 'package:absence_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:absence_app/features/auth/presentation/widgets/auth_validators.dart';
import 'package:absence_app/shared/widgets/common/common_widgets.dart';
import 'package:absence_app/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:absence_app/core/constants/design_constants.dart';
import 'package:absence_app/features/auth/data/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signInWithGoogle();
    
    if (mounted && authProvider.error == null && authProvider.user != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Se o registro foi bem-sucedido, voltar para login ou navegar
      if (mounted && authProvider.error == null && authProvider.user != null) {
        Navigator.of(context).pop();
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
                // Limpar erro ao voltar para login
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
                    Text(
                      'Criar Conta',
                      textAlign: TextAlign.center,
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Preencha os dados para criar sua conta.',
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Mensagem de erro minimalista
                    ErrorMessage(message: authProvider.error),

                    CustomTextField(
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      validator: AuthValidators.validateEmail,
                      onFieldSubmitted: (_) {
                        _passwordFocusNode.requestFocus();
                      },
                    ),

                    const SizedBox(height: 16),
                    CustomTextField(
                      labelText: 'Senha',
                      obscureText: true,
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      validator: AuthValidators.validatePassword,
                      onFieldSubmitted: (_) {
                        _confirmPasswordFocusNode.requestFocus();
                      },
                    ),

                    const SizedBox(height: 16),
                    CustomTextField(
                      labelText: 'Confirmar senha',
                      obscureText: true,
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocusNode,
                      validator: (value) => AuthValidators.validatePasswordConfirmation(
                        value,
                        _passwordController.text,
                      ),
                      onFieldSubmitted: (_) {
                        _handleRegister();
                      },
                    ),

                    const SizedBox(height: 24),
                    AppButton.primary(
                      text: authProvider.isRegisterLoading ? 'Criando conta...' : 'Criar Conta',
                      onPressed: authProvider.isRegisterLoading ? null : _handleRegister,
                      isLoading: authProvider.isRegisterLoading,
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Divider(color: colorScheme.onSurface.withValues(alpha: 0.3))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: DesignConstants.md),
                          child: Text(
                            'ou',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: colorScheme.onSurface.withValues(alpha: 0.3))),
                      ],
                    ),

                    const SizedBox(height: 16),
                    GoogleSignInButton(
                      onPressed: authProvider.isGoogleSignInLoading ? null : _handleGoogleSignIn,
                      isLoading: authProvider.isGoogleSignInLoading,
                    ),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Já tem uma conta? ',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        AppButton.text(
                          text: 'Entrar',
                          fontWeight: FontWeight.w600,
                          onPressed: () {
                            // Limpar erro ao navegar para login
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            authProvider.clearError();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),

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
