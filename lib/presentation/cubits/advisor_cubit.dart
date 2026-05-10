import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/ai_analysis.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/report_data.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/repositories/advisor_ai_repository.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import 'cubit_status.dart';

class AdviceItem {
  const AdviceItem({
    required this.title,
    required this.description,
    required this.level,
  });

  final String title;
  final String description;
  final AdviceLevel level;
}

enum AdviceLevel { positive, warning, danger, info }

class AdvisorState {
  const AdvisorState({
    this.status = CubitStatus.initial,
    this.advices = const [],
    this.projectedBalance = 0,
    this.usingAi = false,
    this.analysisEngine = 'Analisis Lokal',
    this.message,
  });

  final CubitStatus status;
  final List<AdviceItem> advices;
  final double projectedBalance;
  final bool usingAi;
  final String analysisEngine;
  final String? message;

  AdvisorState copyWith({
    CubitStatus? status,
    List<AdviceItem>? advices,
    double? projectedBalance,
    bool? usingAi,
    String? analysisEngine,
    String? message,
  }) {
    return AdvisorState(
      status: status ?? this.status,
      advices: advices ?? this.advices,
      projectedBalance: projectedBalance ?? this.projectedBalance,
      usingAi: usingAi ?? this.usingAi,
      analysisEngine: analysisEngine ?? this.analysisEngine,
      message: message,
    );
  }
}

class AdvisorCubit extends Cubit<AdvisorState> {
  AdvisorCubit(
    this._transactions,
    this._budgets,
    this._goals,
    this._categories,
    this._aiRepository,
    this._preferences,
  )
    : super(const AdvisorState());

  final TransactionRepository _transactions;
  final BudgetRepository _budgets;
  final GoalRepository _goals;
  final CategoryRepository _categories;
  final AdvisorAiRepository _aiRepository;
  final SharedPreferences _preferences;

  Future<void> generateAdvice() async {
    emit(state.copyWith(status: CubitStatus.loading));
    try {
      final now = DateTime.now();
      final start = AppDateUtils.startOfMonth(now);
      final end = AppDateUtils.endOfMonth(now);
      final totalExpense = await _transactions.getTotal(
        TransactionType.expense,
        start,
        end,
      );
      final categorySpending = await _transactions.getExpenseByCategory(
        start,
        end,
      );
      final budgetUsages = await _loadBudgetUsages(
        start,
        end,
        now.month,
        now.year,
      );
      final monthlyComparison = await _transactions.getMonthlyComparison(3);
      final goals = await _goals.getGoals();
      final expenseCategories = await _categories.getCategories(
        type: TransactionType.expense,
      );
      final dedicatedSavingAverage = await _dedicatedSavingAverage(
        expenseCategories,
      );
      final recentTransactions = await _transactions.getTransactions(
        startDate: DateTime(now.year, now.month - 2, 1),
        endDate: end,
      );

      final averageIncome = _average(
        monthlyComparison.map((item) => item.income),
      );
      final averageExpense = _average(
        monthlyComparison.map((item) => item.expense),
      );
      final averageNet = averageIncome - averageExpense;
      final localProjectedBalance = averageNet;
      final localAdvices = <AdviceItem>[];

      _addSpendingAdvices(
        localAdvices,
        categorySpending,
        totalExpense,
        budgetUsages,
      );
      _addCashflowAdvice(
        localAdvices,
        averageIncome,
        averageExpense,
        averageNet,
      );
      _addGoalAdvices(localAdvices, goals, dedicatedSavingAverage, averageNet);

      if (localAdvices.isEmpty) {
        localAdvices.add(
          const AdviceItem(
            title: 'Mulai bangun riwayat transaksi',
            description:
                'Catat pemasukan dan pengeluaran beberapa minggu ke depan agar prediksi dan saran menjadi lebih akurat.',
            level: AdviceLevel.info,
          ),
        );
      }

      var finalAdvices = localAdvices;
      var projectedBalance = localProjectedBalance;
      var usingAi = false;
      var analysisEngine = 'Analisis Lokal';
      String? message;

      final aiEnabled =
          _preferences.getBool(AppConstants.aiAdvisorEnabledKey) ?? false;
      final apiKey =
          (_preferences.getString(AppConstants.aiAdvisorApiKeyKey) ?? '').trim();
      final model = (_preferences.getString(AppConstants.aiAdvisorModelKey) ??
              AppConstants.defaultAiModel)
          .trim();

      if (aiEnabled && apiKey.isNotEmpty) {
        try {
          final aiResult = await _aiRepository.generateFinancialAnalysis(
            apiKey: apiKey,
            model: model.isEmpty ? AppConstants.defaultAiModel : model,
            input: AiAnalysisInput(
              referenceDate: now,
              totalExpenseThisMonth: totalExpense,
              averageIncome: averageIncome,
              averageExpense: averageExpense,
              averageNet: averageNet,
              projectedBalance: localProjectedBalance,
              dedicatedSavingAverage: dedicatedSavingAverage,
              categorySpending: categorySpending,
              budgetUsages: budgetUsages,
              monthlyComparison: monthlyComparison,
              goals: goals,
              recentTransactions: recentTransactions,
            ),
          );
          final aiAdvices = aiResult.advices.map(_fromAiSuggestion).toList();
          if (aiAdvices.isNotEmpty) {
            finalAdvices = aiAdvices;
            projectedBalance = aiResult.projectedBalance ?? localProjectedBalance;
            usingAi = true;
            analysisEngine = 'Analisis AI';
          }
        } catch (_) {
          message =
              'Analisis AI belum tersedia saat ini, aplikasi menggunakan analisis lokal.';
        }
      }

      emit(
        state.copyWith(
          status: CubitStatus.success,
          advices: finalAdvices,
          projectedBalance: projectedBalance,
          usingAi: usingAi,
          analysisEngine: analysisEngine,
          message: message,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(status: CubitStatus.failure, message: error.toString()),
      );
    }
  }

  Future<List<BudgetUsage>> _loadBudgetUsages(
    DateTime start,
    DateTime end,
    int month,
    int year,
  ) async {
    final budgets = await _budgets.getBudgets(month, year);
    final usages = <BudgetUsage>[];
    for (final budget in budgets) {
      final spent = await _transactions.getCategoryExpense(
        budget.categoryId,
        start,
        end,
      );
      usages.add(BudgetUsage(budget: budget, spent: spent));
    }
    return usages;
  }

  Future<double> _dedicatedSavingAverage(
    List<FinanceCategory> categories,
  ) async {
    FinanceCategory? savingCategory;
    for (final category in categories) {
      if (category.name.toLowerCase().contains('tabungan')) {
        savingCategory = category;
        break;
      }
    }
    if (savingCategory?.id == null) {
      return 0;
    }
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 2);
    final end = AppDateUtils.endOfMonth(now);
    final total = await _transactions.getCategoryExpense(
      savingCategory!.id!,
      start,
      end,
    );
    return total / 3;
  }

  void _addSpendingAdvices(
    List<AdviceItem> advices,
    List<CategorySpending> categorySpending,
    double totalExpense,
    List<BudgetUsage> budgetUsages,
  ) {
    for (final spending in categorySpending) {
      if (totalExpense > 0 && spending.total / totalExpense >= 0.5) {
        advices.add(
          AdviceItem(
            title: 'Pengeluaran ${spending.categoryName} dominan',
            description:
                '${spending.categoryName} mengambil lebih dari 50% pengeluaran bulan ini. Coba tetapkan batas mingguan agar arus kas lebih terkendali.',
            level: AdviceLevel.warning,
          ),
        );
      }
    }

    for (final usage in budgetUsages) {
      if (usage.percent >= 1) {
        advices.add(
          AdviceItem(
            title:
                'Anggaran ${usage.budget.categoryName ?? 'kategori'} terlampaui',
            description:
                'Pemakaian sudah ${CurrencyFormatter.format(usage.spent)} dari batas ${CurrencyFormatter.format(usage.budget.limitAmount)}. Kurangi transaksi kategori ini sampai akhir bulan.',
            level: AdviceLevel.danger,
          ),
        );
      } else if (usage.percent >= 0.8) {
        advices.add(
          AdviceItem(
            title: 'Anggaran hampir habis',
            description:
                '${usage.budget.categoryName ?? 'Kategori ini'} sudah memakai ${(usage.percent * 100).toStringAsFixed(0)}% anggaran bulan ini.',
            level: AdviceLevel.warning,
          ),
        );
      }
    }
  }

  void _addCashflowAdvice(
    List<AdviceItem> advices,
    double averageIncome,
    double averageExpense,
    double averageNet,
  ) {
    if (averageIncome <= 0 && averageExpense <= 0) {
      return;
    }
    if (averageNet > 0) {
      advices.add(
        AdviceItem(
          title: 'Saldo rata-rata bertumbuh',
          description:
              'Rata-rata surplus 3 bulan terakhir sekitar ${CurrencyFormatter.format(averageNet)}. Alokasikan 20-30% surplus ke goal atau investasi.',
          level: AdviceLevel.positive,
        ),
      );
    }
    if (averageIncome > 0 && averageExpense >= averageIncome * 0.9) {
      advices.add(
        AdviceItem(
          title: 'Pengeluaran mendekati pemasukan',
          description:
              'Rata-rata pengeluaran sudah mendekati pemasukan. Prioritaskan memangkas kategori non-esensial sebelum menambah komitmen baru.',
          level: AdviceLevel.danger,
        ),
      );
    }
  }

  void _addGoalAdvices(
    List<AdviceItem> advices,
    List<FinancialGoal> goals,
    double dedicatedSavingAverage,
    double averageNet,
  ) {
    final savingCapacity = dedicatedSavingAverage > 0
        ? dedicatedSavingAverage
        : max(0, averageNet * 0.3);
    for (final goal in goals) {
      if (goal.remainingAmount <= 0) {
        advices.add(
          AdviceItem(
            title: '${goal.name} sudah tercapai',
            description:
                'Target sudah terpenuhi. Pertimbangkan membuat goal baru atau mengalihkan dana ke investasi.',
            level: AdviceLevel.positive,
          ),
        );
        continue;
      }
      if (savingCapacity >= goal.suggestedMonthlySaving) {
        advices.add(
          AdviceItem(
            title: '${goal.name} berada di jalur aman',
            description:
                'Butuh ${CurrencyFormatter.format(goal.suggestedMonthlySaving)} per bulan. Kapasitas tabungan saat ini masih cukup untuk mengejar target.',
            level: AdviceLevel.positive,
          ),
        );
      } else if (savingCapacity > 0) {
        final gap = goal.suggestedMonthlySaving - savingCapacity;
        advices.add(
          AdviceItem(
            title: '${goal.name} perlu penyesuaian',
            description:
                'Tambahkan sekitar ${CurrencyFormatter.format(gap)} per bulan atau perpanjang tanggal target agar goal lebih realistis.',
            level: AdviceLevel.warning,
          ),
        );
      } else {
        advices.add(
          AdviceItem(
            title: 'Belum ada kapasitas tabungan untuk ${goal.name}',
            description:
                'Target membutuhkan ${CurrencyFormatter.format(goal.suggestedMonthlySaving)} per bulan. Buat anggaran kategori Tabungan/Goal agar progres lebih terukur.',
            level: AdviceLevel.info,
          ),
        );
      }
    }
  }

  double _average(Iterable<double> values) {
    if (values.isEmpty) {
      return 0;
    }
    return values.reduce((a, b) => a + b) / values.length;
  }

  AdviceItem _fromAiSuggestion(AiAdviceSuggestion suggestion) {
    return AdviceItem(
      title: suggestion.title,
      description: suggestion.description,
      level: switch (suggestion.level) {
        AiAdviceLevel.positive => AdviceLevel.positive,
        AiAdviceLevel.warning => AdviceLevel.warning,
        AiAdviceLevel.danger => AdviceLevel.danger,
        AiAdviceLevel.info => AdviceLevel.info,
      },
    );
  }
}
