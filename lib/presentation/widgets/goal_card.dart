import 'package:flutter/material.dart';

import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/goal.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    this.onAddSaving,
    this.onEdit,
    this.onDelete,
  });

  final FinancialGoal goal;
  final VoidCallback? onAddSaving;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Target ${AppDateUtils.dayMonthYear(goal.targetDate)}',
                      ),
                    ],
                  ),
                ),
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit?.call();
                      } else {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
              value: goal.progress,
              color: scheme.primary,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Terkumpul',
                    value: CurrencyFormatter.format(goal.savedAmount),
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Target',
                    value: CurrencyFormatter.format(goal.targetAmount),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Saran setoran: ${CurrencyFormatter.format(goal.suggestedMonthlySaving)} / bulan',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
            if (onAddSaving != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onAddSaving,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Alokasi'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}
