import 'package:flutter/material.dart';
import '../../../../core/theme/theme_exports.dart';
import '../../../../shared/widgets/layout/spacings.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/providers.dart';

class DashboardGreeting extends StatelessWidget {
  const DashboardGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final displayName = user?.displayName?.trim();
    final greetingName = (displayName != null && displayName.isNotEmpty) ? displayName : 'estudante';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionSpacing(),
        Text(
          'Olá, $greetingName!',
          style: AppTextStyles.greeting(context),
        ),
        const SmallSpacing(),
        Text(
          'Acompanhe seu controle acadêmico!',
          style: AppTextStyles.greetingSubtext(context),
        ),
        const SectionSpacing(),
      ],
    );
  }
}
