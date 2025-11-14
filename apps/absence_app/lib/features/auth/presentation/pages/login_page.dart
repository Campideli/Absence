import 'package:absence_app/features/auth/presentation/pages/register_page.dart';
import 'package:absence_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:absence_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:absence_app/features/auth/presentation/widgets/auth_validators.dart';
import 'package:absence_app/shared/widgets/common/common_widgets.dart';
import 'package:absence_app/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:absence_app/core/constants/design_constants.dart';
import 'package:absence_app/features/auth/data/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (mounted && authProvider.error == null && authProvider.user != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (route) => false,
        );
      }
    }
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



  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 2),
                    Text(
                      'Absence',
                      textAlign: TextAlign.center,
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Sua ferramenta de controle acadêmico.',
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),

                    const Spacer(flex: 3),

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
                        _handleLogin();
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    AppButton.text(
                      text: 'Esqueceu sua senha?',
                      textAlign: TextAlign.right,
                      onPressed: () {
                        // Limpar erro ao navegar para esqueceu a senha
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        authProvider.clearError();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ForgotPasswordPage(
                              initialEmail: _emailController.text.trim(),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    AppButton.primary(
                      text: authProvider.isEmailSignInLoading ? 'Entrando...' : 'Entrar',
                      onPressed: authProvider.isEmailSignInLoading ? null : _handleLogin,
                      isLoading: authProvider.isEmailSignInLoading,
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
                          'Não tem uma conta? ',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        AppButton.text(
                          text: 'Criar conta',
                          fontWeight: FontWeight.w600,
                          onPressed: () {
                            // Limpar erro ao navegar para cadastro
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            authProvider.clearError();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
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
