import 'transaction_type.dart';

class FinanceCategory {
  const FinanceCategory({
    this.id,
    required this.name,
    required this.type,
    required this.iconCodePoint,
    required this.colorHex,
  });

  final int? id;
  final String name;
  final TransactionType type;
  final int iconCodePoint;
  final String colorHex;

  FinanceCategory copyWith({
    int? id,
    String? name,
    TransactionType? type,
    int? iconCodePoint,
    String? colorHex,
  }) {
    return FinanceCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}
