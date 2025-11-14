import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absence_app/features/auth/presentation/providers/auth_provider.dart' as app_auth;
import 'package:absence_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:absence_app/features/auth/presentation/pages/login_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<app_auth.AuthProvider>(
      builder: (context, authProvider, child) {
        // Mostrar loading apenas para operações que não sejam específicas (Google, Email, Register)
        if (authProvider.isLoading && 
            !authProvider.isGoogleSignInLoading && 
            !authProvider.isEmailSignInLoading &&
            !authProvider.isRegisterLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Se usuário está logado, mostrar DashboardPage
        if (authProvider.user != null) {
          return const DashboardPage();
        }

        // Se usuário não está logado, mostrar LoginPage
        return const LoginPage();
      },
    );
  }
}
