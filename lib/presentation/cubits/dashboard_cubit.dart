import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/financial_notification_service.dart';
import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/report_data.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import 'cubit_status.dart';

class DashboardState {
  const DashboardState({
    this.status = CubitStatus.initial,
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.expenseByCategory = const [],
    this.monthlyComparison = const [],
    this.budgetUsages = const [],
    this.goals = const [],
    this.message,
  });

  final CubitStatus status;
  final double totalIncome;
  final double totalExpense;
  final List<CategorySpending> expenseByCategory;
  final List<MonthlyComparison> monthlyComparison;
  final List<BudgetUsage> budgetUsages;
  final List<FinancialGoal> goals;
  final String? message;

  double get netBalance => totalIncome - totalExpense;

  DashboardState copyWith({
    CubitStatus? status,
    double? totalIncome,
    double? totalExpense,
    List<CategorySpending>? expenseByCategory,
    List<MonthlyComparison>? monthlyComparison,
    List<BudgetUsage>? budgetUsages,
    List<FinancialGoal>? goals,
    String? message,
  }) {
    return DashboardState(
      status: status ?? this.status,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      expenseByCategory: expenseByCategory ?? this.expenseByCategory,
      monthlyComparison: monthlyComparison ?? this.monthlyComparison,
      budgetUsages: budgetUsages ?? this.budgetUsages,
      goals: goals ?? this.goals,
      message: message,
    );
  }
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(
    this._transactions,
    this._budgets,
    this._goals,
    this._notifications,
  ) : super(const DashboardState());

  final TransactionRepository _transactions;
  final BudgetRepository _budgets;
  final GoalRepository _goals;
  final FinancialNotificationService _notifications;

  Future<void> loadDashboard() async {
    emit(state.copyWith(status: CubitStatus.loading));
    try {
      final now = DateTime.now();
      final start = AppDateUtils.startOfMonth(now);
      final end = AppDateUtils.endOfMonth(now);
      final income = await _transactions.getTotal(
        TransactionType.income,
        start,
        end,
      );
      final expense = await _transactions.getTotal(
        TransactionType.expense,
        start,
        end,
      );
      final expenseByCategory = await _transactions.getExpenseByCategory(
        start,
        end,
      );
      final monthlyComparison = await _transactions.getMonthlyComparison(6);
      final budgets = await _budgets.getBudgets(now.month, now.year);
      final goals = await _goals.getGoals();
      final netBalance = income - expense;

      final budgetUsages = <BudgetUsage>[];
      for (final budget in budgets) {
        final spent = await _transactions.getCategoryExpense(
          budget.categoryId,
          start,
          end,
        );
        budgetUsages.add(BudgetUsage(budget: budget, spent: spent));
      }

      emit(
        state.copyWith(
          status: CubitStatus.success,
          totalIncome: income,
          totalExpense: expense,
          expenseByCategory: expenseByCategory,
          monthlyComparison: monthlyComparison,
          budgetUsages: budgetUsages,
          goals: goals,
        ),
      );
      try {
        await _notifications.notifyIfBalanceIsNegative(netBalance);
      } catch (_) {
        // Notification failures should not block dashboard data.
      }
    } catch (error) {
      emit(
        state.copyWith(status: CubitStatus.failure, message: error.toString()),
      );
    }
  }
}
