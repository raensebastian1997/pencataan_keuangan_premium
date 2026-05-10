import '../entities/budget.dart';

abstract class BudgetRepository {
  Future<List<Budget>> getBudgets(int month, int year);
  Future<int> saveBudget(Budget budget);
  Future<void> deleteBudget(int id);
}
