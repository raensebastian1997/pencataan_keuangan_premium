import 'transaction_type.dart';

class FinancialTransaction {
  const FinancialTransaction({
    this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.note,
    this.categoryName,
    this.categoryColorHex,
    this.categoryIconCodePoint,
  });

  final int? id;
  final double amount;
  final TransactionType type;
  final int categoryId;
  final DateTime date;
  final String? note;
  final String? categoryName;
  final String? categoryColorHex;
  final int? categoryIconCodePoint;

  FinancialTransaction copyWith({
    int? id,
    double? amount,
    TransactionType? type,
    int? categoryId,
    DateTime? date,
    String? note,
    String? categoryName,
    String? categoryColorHex,
    int? categoryIconCodePoint,
  }) {
    return FinancialTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
      categoryName: categoryName ?? this.categoryName,
      categoryColorHex: categoryColorHex ?? this.categoryColorHex,
      categoryIconCodePoint:
          categoryIconCodePoint ?? this.categoryIconCodePoint,
    );
  }
}
