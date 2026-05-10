import 'package:flutter/material.dart';

import '../cubits/advisor_cubit.dart';

class AdviceCard extends StatelessWidget {
  const AdviceCard({super.key, required this.advice});

  final AdviceItem advice;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(advice.level);
    final icon = _iconFor(advice.level);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.16),
              foregroundColor: color,
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    advice.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(advice.description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(AdviceLevel level) {
    return switch (level) {
      AdviceLevel.positive => Colors.green,
      AdviceLevel.warning => Colors.orange,
      AdviceLevel.danger => Colors.red,
      AdviceLevel.info => Colors.blue,
    };
  }

  IconData _iconFor(AdviceLevel level) {
    return switch (level) {
      AdviceLevel.positive => Icons.check_circle,
      AdviceLevel.warning => Icons.warning_amber_rounded,
      AdviceLevel.danger => Icons.priority_high_rounded,
      AdviceLevel.info => Icons.tips_and_updates,
    };
  }
}
