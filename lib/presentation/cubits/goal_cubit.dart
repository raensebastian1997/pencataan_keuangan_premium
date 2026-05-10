import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import 'cubit_status.dart';

class GoalState {
  const GoalState({
    this.status = CubitStatus.initial,
    this.goals = const [],
    this.message,
  });

  final CubitStatus status;
  final List<FinancialGoal> goals;
  final String? message;

  GoalState copyWith({
    CubitStatus? status,
    List<FinancialGoal>? goals,
    String? message,
  }) {
    return GoalState(
      status: status ?? this.status,
      goals: goals ?? this.goals,
      message: message,
    );
  }
}

class GoalCubit extends Cubit<GoalState> {
  GoalCubit(this._repository) : super(const GoalState());

  final GoalRepository _repository;

  Future<void> loadGoals() async {
    emit(state.copyWith(status: CubitStatus.loading));
    try {
      final goals = await _repository.getGoals();
      emit(state.copyWith(status: CubitStatus.success, goals: goals));
    } catch (error) {
      emit(
        state.copyWith(status: CubitStatus.failure, message: error.toString()),
      );
    }
  }

  Future<void> saveGoal(FinancialGoal goal) async {
    try {
      await _repository.saveGoal(goal);
      await loadGoals();
    } catch (error) {
      emit(
        state.copyWith(status: CubitStatus.failure, message: error.toString()),
      );
    }
  }

  Future<void> allocateToGoal(FinancialGoal goal, double amount) async {
    final updated = goal.copyWith(savedAmount: goal.savedAmount + amount);
    await saveGoal(updated);
  }

  Future<void> deleteGoal(int id) async {
    try {
      await _repository.deleteGoal(id);
      await loadGoals();
    } catch (error) {
      emit(
        state.copyWith(status: CubitStatus.failure, message: error.toString()),
      );
    }
  }
}
