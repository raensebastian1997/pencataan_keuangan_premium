import '../entities/category.dart';
import '../entities/transaction_type.dart';

abstract class CategoryRepository {
  Future<List<FinanceCategory>> getCategories({TransactionType? type});
  Future<FinanceCategory?> getCategoryById(int id);
  Future<int> saveCategory(FinanceCategory category);
  Future<void> deleteCategory(int id);
  Future<bool> isCategoryInUse(int id);
}
