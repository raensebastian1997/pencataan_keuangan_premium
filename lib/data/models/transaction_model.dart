import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_type.dart';

class TransactionModel extends FinancialTransaction {
  const TransactionModel({
    super.id,
    required super.amount,
    required super.type,
    required super.categoryId,
    required super.date,
    super.note,
    super.categoryName,
    super.categoryColorHex,
    super.categoryIconCodePoint,
  });

  factory TransactionModel.fromEntity(FinancialTransaction transaction) {
    return TransactionModel(
      id: transaction.id,
      amount: transaction.amount,
      type: transaction.type,
      categoryId: transaction.categoryId,
      date: transaction.date,
      note: transaction.note,
      categoryName: transaction.categoryName,
      categoryColorHex: transaction.categoryColorHex,
      categoryIconCodePoint: transaction.categoryIconCodePoint,
    );
  }

  factory TransactionModel.fromMap(Map<String, Object?> map) {
    return TransactionModel(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      type: transactionTypeFromString(map['type'] as String),
      categoryId: map['category_id'] as int,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      categoryName: map['category_name'] as String?,
      categoryColorHex: map['category_color_hex'] as String?,
      categoryIconCodePoint: map['category_icon_code_point'] as int?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'type': type.value,
      'category_id': categoryId,
      'date': date.toIso8601String(),
      'note': note,
    };
  }
}
