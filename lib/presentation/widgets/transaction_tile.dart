import 'package:flutter/material.dart';

import '../../core/utils/color_utils.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/utils/material_icon_resolver.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_type.dart';

enum TransactionTileAction { edit, delete }

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    required this.onActionSelected,
  });

  final FinancialTransaction transaction;
  final VoidCallback? onTap;
  final ValueChanged<TransactionTileAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final categoryColor = ColorUtils.fromHex(
      transaction.categoryColorHex ?? '#00A884',
    );
    final amountColor = isIncome
        ? const Color(0xFF11A059)
        : const Color(0xFF171A22);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: categoryColor.withValues(alpha: 0.16),
                foregroundColor: categoryColor,
                child: Icon(
                  MaterialIconResolver.fromCodePoint(
                    transaction.categoryIconCodePoint ?? Icons.category.codePoint,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.categoryName ?? 'Kategori',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        transaction.type.label,
                        AppDateUtils.dayMonthYear(transaction.date),
                        if ((transaction.note ?? '').isNotEmpty) transaction.note!,
                      ].join(' • '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<TransactionTileAction>(
                onSelected: onActionSelected,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: TransactionTileAction.edit,
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: TransactionTileAction.delete,
                    child: Text('Hapus'),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: amountColor,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isIncome ? 'Success' : 'Paid',
                    style: TextStyle(
                      color: isIncome
                          ? const Color(0xFF11A059)
                          : const Color(0xFF7E8794),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
