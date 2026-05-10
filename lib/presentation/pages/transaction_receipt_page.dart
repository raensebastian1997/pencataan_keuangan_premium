import 'package:flutter/material.dart';

import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/transaction_type.dart';

class TransactionReceiptPage extends StatelessWidget {
  const TransactionReceiptPage({
    super.key,
    required this.type,
    required this.amount,
    required this.date,
    required this.categoryName,
    required this.note,
  });

  final TransactionType type;
  final double amount;
  final DateTime date;
  final String categoryName;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F6),
      appBar: AppBar(
        title: const Text('Receipt', style: TextStyle(fontSize: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            children: [
              Expanded(
                child: Card(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 26, 18, 20),
                        child: Column(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFE8F5FD),
                              ),
                              child: const Icon(
                                Icons.verified_rounded,
                                size: 52,
                                color: Color(0xFF1498EA),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Transfer Success',
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Transaksi berhasil diproses',
                              style: TextStyle(color: Color(0xFF778092)),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              '${type == TransactionType.expense ? '-' : '+'}${CurrencyFormatter.format(amount)}',
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                color: type == TransactionType.expense
                                    ? const Color(0xFF171A22)
                                    : const Color(0xFF129659),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Details',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _DetailRow(label: 'Kategori', value: categoryName),
                              _DetailRow(
                                label: 'Tanggal',
                                value: AppDateUtils.dayMonthYear(date),
                              ),
                              _DetailRow(
                                label: 'Jenis',
                                value: type == TransactionType.expense
                                    ? 'Pengeluaran'
                                    : 'Pemasukan',
                              ),
                              _DetailRow(
                                label: 'Amount Used',
                                value: CurrencyFormatter.format(amount),
                              ),
                              _DetailRow(
                                label: 'Catatan',
                                value: note.isEmpty ? '-' : note,
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF171A22),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF778092), fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
