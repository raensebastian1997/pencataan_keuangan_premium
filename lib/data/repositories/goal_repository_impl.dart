import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../datasources/local_database.dart';
import '../models/goal_model.dart';

class GoalRepositoryImpl implements GoalRepository {
  const GoalRepositoryImpl(this._database);

  final LocalDatabase _database;

  @override
  Future<List<FinancialGoal>> getGoals() async {
    final rows = await _database.getGoals();
    return rows.map(GoalModel.fromMap).toList();
  }

  @override
  Future<int> saveGoal(FinancialGoal goal) async {
    final model = GoalModel.fromEntity(goal);
    if (goal.id == null) {
      return _database.insertGoal(model.toMap());
    }
    await _database.updateGoal(goal.id!, model.toMap());
    return goal.id!;
  }

  @override
  Future<void> deleteGoal(int id) async {
    await _database.deleteGoal(id);
  }
}
