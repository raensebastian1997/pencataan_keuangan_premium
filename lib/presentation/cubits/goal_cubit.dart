import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/financial_notification_service.dart';
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
  GoalCubit(this._repository, this._notifications) : super(const GoalState());

  final GoalRepository _repository;
  final FinancialNotificationService _notifications;

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
      await _notifyInputSaved(
        'Goal tersimpan',
        '${goal.name} berhasil disimpan.',
      );
    } catch (error) {
      emit(
        state.copyWith(status: CubitStatus.failure, message: error.toString()),
      );
    }
  }

  Future<void> _notifyInputSaved(String title, String body) async {
    try {
      await _notifications.showInputSavedNotification(title: title, body: body);
    } catch (_) {
      // Notification failures should not block saved data.
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
