import '../entities/report_data.dart';
import '../entities/transaction.dart';
import '../entities/transaction_type.dart';

abstract class TransactionRepository {
  Future<List<FinancialTransaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
  });

  Future<int> saveTransaction(FinancialTransaction transaction);
  Future<void> deleteTransaction(int id);
  Future<double> getTotal(
    TransactionType type,
    DateTime startDate,
    DateTime endDate,
  );
  Future<double> getCategoryExpense(
    int categoryId,
    DateTime startDate,
    DateTime endDate,
  );
  Future<List<CategorySpending>> getExpenseByCategory(
    DateTime startDate,
    DateTime endDate,
  );
  Future<List<MonthlyComparison>> getMonthlyComparison(int months);
}
