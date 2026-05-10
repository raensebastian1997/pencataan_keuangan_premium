import 'budget.dart';

class CategorySpending {
  const CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColorHex,
    required this.total,
  });

  final int categoryId;
  final String categoryName;
  final String categoryColorHex;
  final double total;
}

class MonthlyComparison {
  const MonthlyComparison({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final double income;
  final double expense;

  double get balance => income - expense;
}

class BudgetUsage {
  const BudgetUsage({required this.budget, required this.spent});

  final Budget budget;
  final double spent;

  double get percent =>
      budget.limitAmount <= 0 ? 0 : spent / budget.limitAmount;
  double get remaining =>
      (budget.limitAmount - spent).clamp(0, double.infinity).toDouble();
}
