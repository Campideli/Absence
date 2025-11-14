import 'package:flutter/material.dart';

class AbsenceCard extends StatelessWidget {
  final dynamic absence;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AbsenceCard({
    super.key,
    required this.absence,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text('Absence Card - Implementar'),
        onTap: onTap,
      ),
    );
  }
}