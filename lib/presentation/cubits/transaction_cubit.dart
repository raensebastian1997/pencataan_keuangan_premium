import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import 'cubit_status.dart';

class TransactionState {
  const TransactionState({
    this.status = CubitStatus.initial,
    this.transactions = const [],
    this.categories = const [],
    this.startDate,
    this.endDate,
    this.categoryId,
    this.message,
  });

  final CubitStatus status;
  final List<FinancialTransaction> transactions;
  final List<FinanceCategory> categories;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? categoryId;
  final String? message;

  TransactionState copyWith({
    CubitStatus? status,
    List<FinancialTransaction>? transactions,
    List<FinanceCategory>? categories,
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearCategory = false,
    String? message,
  }) {
    return TransactionState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      categories: categories ?? this.categories,
      startDate: clearStartDate ? null : startDate ?? this.startDate,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      message: message,
    );
  }
}

class TransactionCubit extends Cubit<TransactionState> {
  TransactionCubit(this._transactions, this._categories)
    : super(const TransactionState());

  final TransactionRepository _transactions;
  final CategoryRepository _categories;

  Future<void> loadTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    bool clearFilters = false,
  }) async {
    emit(state.copyWith(status: CubitStatus.loading));
    try {
      final categories = await _categories.getCategories();
      final transactions = await _transactions.getTransactions(
        startDate: clearFilters ? null : startDate,
        endDate: clearFilters ? null : endDate,
        categoryId: clearFilters ? null : categoryId,
      );
      emit(
        state.copyWith(
          status: CubitStatus.success,
          transactions: transactions,
          categories: categories,
          startDate: clearFilters ? null : startDate,
          endDate: clearFilters ? null : endDate,
          categoryId: clearFilters ? null : categoryId,
          clearStartDate: clearFilters || startDate == null,
          clearEndDate: clearFilters || endDate == null,
          clearCategory: clearFilters || categoryId == null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(status: CubitStatus.failure, message: error.toString()),
      );
    }
  }

  Future<void> saveTransaction(FinancialTransaction transaction) async {
    try {
      await _transactions.saveTransaction(transaction);
      await loadTransactions();
    } catch (error) {
      emit(
        state.copyWith(status: CubitStatus.failure, message: error.toString()),
      );
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await _transactions.deleteTransaction(id);
      await loadTransactions();
    } catch (error) {
      emit(
        state.copyWith(status: CubitStatus.failure, message: error.toString()),
      );
    }
  }
}
