import '../../domain/entities/report_data.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/local_database.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(this._database);

  final LocalDatabase _database;

  @override
  Future<List<FinancialTransaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
  }) async {
    final rows = await _database.getTransactions(
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  @override
  Future<int> saveTransaction(FinancialTransaction transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    if (transaction.id == null) {
      return _database.insertTransaction(model.toMap());
    }
    await _database.updateTransaction(transaction.id!, model.toMap());
    return transaction.id!;
  }

  @override
  Future<void> deleteTransaction(int id) async {
    await _database.deleteTransaction(id);
  }

  @override
  Future<double> getTotal(
    TransactionType type,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _database.getTotal(type.value, startDate, endDate);
  }

  @override
  Future<double> getCategoryExpense(
    int categoryId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _database.getCategoryExpense(categoryId, startDate, endDate);
  }

  @override
  Future<List<CategorySpending>> getExpenseByCategory(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final rows = await _database.getExpenseByCategory(startDate, endDate);
    return rows.map((row) {
      return CategorySpending(
        categoryId: row['category_id'] as int,
        categoryName: row['category_name'] as String,
        categoryColorHex: row['category_color_hex'] as String,
        total: (row['total'] as num).toDouble(),
      );
    }).toList();
  }

  @override
  Future<List<MonthlyComparison>> getMonthlyComparison(int months) async {
    final now = DateTime.now();
    final startMonth = DateTime(now.year, now.month - months + 1);
    final rows = await _database.getMonthlyComparison(startMonth);
    final lookup = <String, Map<String, Object?>>{
      for (final row in rows) row['month_key'] as String: row,
    };

    return List.generate(months, (index) {
      final month = DateTime(startMonth.year, startMonth.month + index);
      final key = _monthKey(month);
      final row = lookup[key];
      return MonthlyComparison(
        month: month,
        income: row == null ? 0 : (row['income'] as num).toDouble(),
        expense: row == null ? 0 : (row['expense'] as num).toDouble(),
      );
    });
  }

  String _monthKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
  }
}
