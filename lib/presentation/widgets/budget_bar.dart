import 'package:flutter/material.dart';

import '../../core/utils/color_utils.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/material_icon_resolver.dart';
import '../../domain/entities/report_data.dart';

class BudgetBar extends StatelessWidget {
  const BudgetBar({super.key, required this.usage, this.onEdit, this.onDelete});

  final BudgetUsage usage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final percent = usage.percent;
    final progressColor = percent >= 1
        ? Colors.red
        : percent >= 0.8
        ? Colors.orange
        : Colors.green;
    final categoryColor = ColorUtils.fromHex(
      usage.budget.categoryColorHex ?? '#00A884',
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: categoryColor.withValues(alpha: 0.16),
                  foregroundColor: categoryColor,
                  child: Icon(
                    MaterialIconResolver.fromCodePoint(
                      usage.budget.categoryIconCodePoint ??
                          Icons.category.codePoint,
                    ),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    usage.budget.categoryName ?? 'Kategori',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
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
              value: percent.clamp(0, 1).toDouble(),
              color: progressColor,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${CurrencyFormatter.format(usage.spent)} dari ${CurrencyFormatter.format(usage.budget.limitAmount)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '${(percent * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: progressColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
