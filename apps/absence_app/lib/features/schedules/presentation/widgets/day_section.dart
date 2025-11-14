import 'package:flutter/material.dart';

class DaySection extends StatelessWidget {
  final String weekdayLabel;
  final List<Widget> entries;
  const DaySection({required this.weekdayLabel, required this.entries, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            weekdayLabel,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ...entries,
      ],
    );
  }
}
