import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/local_database.dart';
import '../models/budget_model.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  const BudgetRepositoryImpl(this._database);

  final LocalDatabase _database;

  @override
  Future<List<Budget>> getBudgets(int month, int year) async {
    final rows = await _database.getBudgets(month, year);
    return rows.map(BudgetModel.fromMap).toList();
  }

  @override
  Future<int> saveBudget(Budget budget) {
    return _database.upsertBudget(BudgetModel.fromEntity(budget).toMap());
  }

  @override
  Future<void> deleteBudget(int id) async {
    await _database.deleteBudget(id);
  }
}
