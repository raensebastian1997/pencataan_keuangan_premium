import '../entities/goal.dart';

abstract class GoalRepository {
  Future<List<FinancialGoal>> getGoals();
  Future<int> saveGoal(FinancialGoal goal);
  Future<void> deleteGoal(int id);
}
