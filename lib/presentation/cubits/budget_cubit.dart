import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/financial_notification_service.dart';
import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/report_data.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import 'cubit_status.dart';

class BudgetState {
  const BudgetState({
    this.status = CubitStatus.initial,
    required this.month,
    this.usages = const [],
    this.categories = const [],
    this.message,
  });

  final CubitStatus status;
  final DateTime month;
  final List<BudgetUsage> usages;
  final List<FinanceCategory> categories;
  final String? message;

  BudgetState copyWith({
    CubitStatus? status,
    DateTime? month,
    List<BudgetUsage>? usages,
    List<FinanceCategory>? categories,
    String? message,
  }) {
    return BudgetState(
      status: status ?? this.status,
      month: month ?? this.month,
      usages: usages ?? this.usages,
      categories: categories ?? this.categories,
      message: message,
    );
  }
}

class BudgetCubit extends Cubit<BudgetState> {
  BudgetCubit(
    this._budgets,
    this._transactions,
    this._categories,
    this._notifications,
  ) : super(BudgetState(month: AppDateUtils.startOfMonth(DateTime.now())));

  final BudgetRepository _budgets;
  final TransactionRepository _transactions;
  final CategoryRepository _categories;
  final FinancialNotificationService _notifications;

  Future<void> loadCurrentMonth() {
    return loadMonth(AppDateUtils.startOfMonth(DateTime.now()));
  }

  Future<void> loadMonth(DateTime month) async {
    emit(
      state.copyWith(
        status: CubitStatus.loading,
        month: AppDateUtils.startOfMonth(month),
      ),
    );
    try {
      final selectedMonth = AppDateUtils.startOfMonth(month);
      final monthBudgets = await _budgets.getBudgets(
        selectedMonth.month,
        selectedMonth.year,
      );
      final start = AppDateUtils.startOfMonth(selectedMonth);
      final end = AppDateUtils.endOfMonth(selectedMonth);
      final usages = <BudgetUsage>[];
      for (final budget in monthBudgets) {
        final spent = await _transactions.getCategoryExpense(
          budget.categoryId,
          start,
          end,
        );
        usages.add(BudgetUsage(budget: budget, spent: spent));
      }
      final categories = await _categories.getCategories(
        type: TransactionType.expense,
      );
      emit(
        state.copyWith(
          status: CubitStatus.success,
          month: selectedMonth,
          usages: usages,
          categories: categories,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(status: CubitStatus.failure, message: error.toString()),
      );
    }
  }

  Future<void> previousMonth() =>
      loadMonth(DateTime(state.month.year, state.month.month - 1));

  Future<void> nextMonth() =>
      loadMonth(DateTime(state.month.year, state.month.month + 1));

  Future<void> saveBudget(Budget budget) async {
    try {
      await _budgets.saveBudget(budget);
      await loadMonth(DateTime(budget.year, budget.month));
      await _notifyInputSaved(
        'Budget tersimpan',
        'Budget bulan ini berhasil disimpan.',
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

  Future<void> deleteBudget(int id) async {
    try {
      await _budgets.deleteBudget(id);
      await loadMonth(state.month);
    } catch (error) {
      emit(
        state.copyWith(status: CubitStatus.failure, message: error.toString()),
      );
    }
  }
}
