import '../../domain/entities/category.dart';
import '../../domain/entities/transaction_type.dart';

class CategoryModel extends FinanceCategory {
  const CategoryModel({
    super.id,
    required super.name,
    required super.type,
    required super.iconCodePoint,
    required super.colorHex,
  });

  factory CategoryModel.fromEntity(FinanceCategory category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      type: category.type,
      iconCodePoint: category.iconCodePoint,
      colorHex: category.colorHex,
    );
  }

  factory CategoryModel.fromMap(Map<String, Object?> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: transactionTypeFromString(map['type'] as String),
      iconCodePoint: map['icon_code_point'] as int,
      colorHex: map['color_hex'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type.value,
      'icon_code_point': iconCodePoint,
      'color_hex': colorHex,
    };
  }
}
