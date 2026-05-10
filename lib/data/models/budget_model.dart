import '../../domain/entities/budget.dart';

class BudgetModel extends Budget {
  const BudgetModel({
    super.id,
    required super.categoryId,
    required super.month,
    required super.year,
    required super.limitAmount,
    super.categoryName,
    super.categoryColorHex,
    super.categoryIconCodePoint,
  });

  factory BudgetModel.fromEntity(Budget budget) {
    return BudgetModel(
      id: budget.id,
      categoryId: budget.categoryId,
      month: budget.month,
      year: budget.year,
      limitAmount: budget.limitAmount,
      categoryName: budget.categoryName,
      categoryColorHex: budget.categoryColorHex,
      categoryIconCodePoint: budget.categoryIconCodePoint,
    );
  }

  factory BudgetModel.fromMap(Map<String, Object?> map) {
    return BudgetModel(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int,
      month: map['month'] as int,
      year: map['year'] as int,
      limitAmount: (map['limit_amount'] as num).toDouble(),
      categoryName: map['category_name'] as String?,
      categoryColorHex: map['category_color_hex'] as String?,
      categoryIconCodePoint: map['category_icon_code_point'] as int?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'category_id': categoryId,
      'month': month,
      'year': year,
      'limit_amount': limitAmount,
    };
  }
}
