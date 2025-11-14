import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarHeader extends StatelessWidget {
  final DateTime shownMonth;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  const CalendarHeader({
    super.key,
    required this.shownMonth,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: onPrevMonth, icon: const Icon(Icons.chevron_left)),
        Text(
          DateFormat("MMMM 'de' yyyy", 'pt_BR').format(shownMonth),
          style: textTheme.titleLarge,
        ),
        IconButton(onPressed: onNextMonth, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}
