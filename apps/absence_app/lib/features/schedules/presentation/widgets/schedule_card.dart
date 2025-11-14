import 'package:flutter/material.dart';

class ScheduleCard extends StatelessWidget {
  final String subjectName;
  final String startTime;
  const ScheduleCard({required this.subjectName, required this.startTime, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(Icons.schedule, color: Theme.of(context).colorScheme.primary),
        title: Text(subjectName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(startTime, style: const TextStyle(fontSize: 15)),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
