import '../../core/utils/date_time_utils.dart';

class FinancialGoal {
  const FinancialGoal({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.targetDate,
    required this.savedAmount,
  });

  final int? id;
  final String name;
  final double targetAmount;
  final DateTime targetDate;
  final double savedAmount;

  double get progress {
    if (targetAmount <= 0) {
      return 0;
    }
    return (savedAmount / targetAmount).clamp(0, 1).toDouble();
  }

  double get remainingAmount =>
      (targetAmount - savedAmount).clamp(0, double.infinity).toDouble();

  int get monthsRemaining => AppDateUtils.monthsUntil(targetDate);

  double get suggestedMonthlySaving => remainingAmount / monthsRemaining;

  FinancialGoal copyWith({
    int? id,
    String? name,
    double? targetAmount,
    DateTime? targetDate,
    double? savedAmount,
  }) {
    return FinancialGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
      savedAmount: savedAmount ?? this.savedAmount,
    );
  }
}
