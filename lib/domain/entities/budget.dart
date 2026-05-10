class Budget {
  const Budget({
    this.id,
    required this.categoryId,
    required this.month,
    required this.year,
    required this.limitAmount,
    this.categoryName,
    this.categoryColorHex,
    this.categoryIconCodePoint,
  });

  final int? id;
  final int categoryId;
  final int month;
  final int year;
  final double limitAmount;
  final String? categoryName;
  final String? categoryColorHex;
  final int? categoryIconCodePoint;

  Budget copyWith({
    int? id,
    int? categoryId,
    int? month,
    int? year,
    double? limitAmount,
    String? categoryName,
    String? categoryColorHex,
    int? categoryIconCodePoint,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      month: month ?? this.month,
      year: year ?? this.year,
      limitAmount: limitAmount ?? this.limitAmount,
      categoryName: categoryName ?? this.categoryName,
      categoryColorHex: categoryColorHex ?? this.categoryColorHex,
      categoryIconCodePoint:
          categoryIconCodePoint ?? this.categoryIconCodePoint,
    );
  }
}
