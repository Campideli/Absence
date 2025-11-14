import 'package:flutter/material.dart';

class AbsenceDetailsPage extends StatelessWidget {
  final dynamic absence;

  const AbsenceDetailsPage({super.key, required this.absence});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Falta'),
      ),
      body: const Center(
        child: Text('Página de detalhes - Implementar'),
      ),
    );
  }
}