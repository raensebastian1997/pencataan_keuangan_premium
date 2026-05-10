import 'goal.dart';
import 'report_data.dart';
import 'transaction.dart';

enum AiAdviceLevel { positive, warning, danger, info }

class AiAdviceSuggestion {
  const AiAdviceSuggestion({
    required this.title,
    required this.description,
    required this.level,
  });

  final String title;
  final String description;
  final AiAdviceLevel level;
}

class AiAnalysisInput {
  const AiAnalysisInput({
    required this.referenceDate,
    required this.totalExpenseThisMonth,
    required this.averageIncome,
    required this.averageExpense,
    required this.averageNet,
    required this.projectedBalance,
    required this.dedicatedSavingAverage,
    required this.categorySpending,
    required this.budgetUsages,
    required this.monthlyComparison,
    required this.goals,
    required this.recentTransactions,
  });

  final DateTime referenceDate;
  final double totalExpenseThisMonth;
  final double averageIncome;
  final double averageExpense;
  final double averageNet;
  final double projectedBalance;
  final double dedicatedSavingAverage;
  final List<CategorySpending> categorySpending;
  final List<BudgetUsage> budgetUsages;
  final List<MonthlyComparison> monthlyComparison;
  final List<FinancialGoal> goals;
  final List<FinancialTransaction> recentTransactions;
}

class AiAnalysisOutput {
  const AiAnalysisOutput({
    required this.advices,
    this.projectedBalance,
    this.summary,
  });

  final List<AiAdviceSuggestion> advices;
  final double? projectedBalance;
  final String? summary;
}
