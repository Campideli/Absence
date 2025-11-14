import 'package:absence_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:absence_app/features/subjects/presentation/providers/subject_provider.dart';
import 'package:absence_app/features/absences/presentation/providers/absence_provider.dart';
import 'package:absence_app/core/theme/theme_provider.dart';
import 'package:absence_app/features/auth/data/auth_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_themes.dart';
import 'config/app_config.dart';
import 'config/env_config.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await EnvConfig.load();
  await Firebase.initializeApp(options: AppConfig.firebaseOptions);
  // Initialize locale/date formatting data for intl
  await initializeDateFormatting();
  
  runApp(const AbsenceApp());
}

class AbsenceApp extends StatelessWidget {
  const AbsenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => SubjectProvider()),
        ChangeNotifierProvider(create: (context) => AbsenceProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Absence',
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
