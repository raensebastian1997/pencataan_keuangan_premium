import '../../domain/entities/category.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/local_database.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl(this._database);

  final LocalDatabase _database;

  @override
  Future<List<FinanceCategory>> getCategories({TransactionType? type}) async {
    final rows = await _database.getCategories(type: type?.value);
    return rows.map(CategoryModel.fromMap).toList();
  }

  @override
  Future<FinanceCategory?> getCategoryById(int id) async {
    final row = await _database.getCategoryById(id);
    return row == null ? null : CategoryModel.fromMap(row);
  }

  @override
  Future<int> saveCategory(FinanceCategory category) async {
    final model = CategoryModel.fromEntity(category);
    if (category.id == null) {
      return _database.insertCategory(model.toMap());
    }
    await _database.updateCategory(category.id!, model.toMap());
    return category.id!;
  }

  @override
  Future<void> deleteCategory(int id) async {
    await _database.deleteCategory(id);
  }

  @override
  Future<bool> isCategoryInUse(int id) => _database.isCategoryInUse(id);
}
