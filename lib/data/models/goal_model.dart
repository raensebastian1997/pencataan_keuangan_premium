import '../../domain/entities/goal.dart';

class GoalModel extends FinancialGoal {
  const GoalModel({
    super.id,
    required super.name,
    required super.targetAmount,
    required super.targetDate,
    required super.savedAmount,
  });

  factory GoalModel.fromEntity(FinancialGoal goal) {
    return GoalModel(
      id: goal.id,
      name: goal.name,
      targetAmount: goal.targetAmount,
      targetDate: goal.targetDate,
      savedAmount: goal.savedAmount,
    );
  }

  factory GoalModel.fromMap(Map<String, Object?> map) {
    return GoalModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      targetDate: DateTime.parse(map['target_date'] as String),
      savedAmount: (map['saved_amount'] as num).toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'target_amount': targetAmount,
      'target_date': targetDate.toIso8601String(),
      'saved_amount': savedAmount,
    };
  }
}
