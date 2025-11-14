import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../subjects/presentation/providers/subject_provider.dart';
import '../../../absences/presentation/providers/absence_provider.dart';
import '../../../subjects/presentation/pages/subjects_page.dart';
import '../../../absences/presentation/pages/absences_page.dart';
import '../widgets/dashboard_home.dart';
import '../../../../shared/widgets/navigation/custom_bottom_nav_bar.dart';
import '../../../schedules/presentation/pages/schedules_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  void setCurrentIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  
  final List<Widget> _pages = [
    const DashboardHome(),
    const SubjectsPage(),
    const AbsencesPage(),
    const CalendarPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    // Só carrega dados se há um usuário autenticado
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<SubjectProvider>().loadSubjects();
      context.read<AbsenceProvider>().loadUserAbsences();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mantém o estado de todas as páginas mas só renderiza a visível
      // Isso evita rebuilds desnecessários em páginas que não estão sendo exibidas
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          NavItem(
            icon: Icons.school_outlined,
            activeIcon: Icons.school,
            label: 'Matérias',
          ),
          NavItem(
            icon: Icons.event_busy_outlined,
            activeIcon: Icons.event_busy,
            label: 'Faltas',
          ),
          NavItem(
            icon: Icons.schedule_outlined,
            activeIcon: Icons.schedule,
            label: 'Horários',
          ),
        ],
      ),
    );
  }
}
