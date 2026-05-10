import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/ai_analysis.dart';
import '../../domain/entities/transaction_type.dart';

class AiAdvisorRemoteDataSource {
  AiAdvisorRemoteDataSource(this._client);

  final http.Client _client;

  static final Uri _endpoint = Uri.parse(
    'https://api.openai.com/v1/chat/completions',
  );

  Future<AiAnalysisOutput> generateFinancialAnalysis({
    required String apiKey,
    required String model,
    required AiAnalysisInput input,
  }) async {
    final payload = _buildPayload(input);
    final response = await _client.post(
      _endpoint,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'temperature': 0.2,
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {
            'role': 'user',
            'content': jsonEncode(payload),
          },
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('AI API error (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw const FormatException('Respons AI tidak berisi pilihan jawaban.');
    }

    final message = choices.first as Map<String, dynamic>;
    final content =
        ((message['message'] as Map<String, dynamic>)['content'] as String?)
            ?.trim() ??
        '';
    if (content.isEmpty) {
      throw const FormatException('Konten respons AI kosong.');
    }

    final aiJson = _decodeJsonFromText(content);
    final projectedBalance = (aiJson['projected_balance'] as num?)?.toDouble();
    final summary = aiJson['summary'] as String?;

    final advicesRaw = aiJson['advices'] as List<dynamic>? ?? const [];
    final advices = advicesRaw.map((item) {
      final map = item as Map<String, dynamic>;
      return AiAdviceSuggestion(
        title: (map['title'] as String? ?? '').trim(),
        description: (map['description'] as String? ?? '').trim(),
        level: _parseLevel((map['level'] as String? ?? '').trim()),
      );
    }).where((item) => item.title.isNotEmpty && item.description.isNotEmpty).toList();

    if (advices.isEmpty) {
      throw const FormatException('AI tidak mengembalikan daftar saran yang valid.');
    }

    return AiAnalysisOutput(
      advices: advices,
      projectedBalance: projectedBalance,
      summary: summary,
    );
  }

  Map<String, dynamic> _buildPayload(AiAnalysisInput input) {
    final monthFormatter = DateFormat('yyyy-MM');

    return {
      'reference_date': AppDateUtils.dayMonthYear(input.referenceDate),
      'summary': {
        'projected_balance': input.projectedBalance,
        'average_income_last_3_months': input.averageIncome,
        'average_expense_last_3_months': input.averageExpense,
        'average_net_last_3_months': input.averageNet,
        'total_expense_this_month': input.totalExpenseThisMonth,
        'dedicated_saving_average': input.dedicatedSavingAverage,
      },
      'monthly_comparison': input.monthlyComparison.map((item) {
        return {
          'month': monthFormatter.format(item.month),
          'income': item.income,
          'expense': item.expense,
          'balance': item.balance,
        };
      }).toList(),
      'category_spending_this_month': input.categorySpending.map((item) {
        return {
          'category_name': item.categoryName,
          'amount': item.total,
        };
      }).toList(),
      'budget_usage_this_month': input.budgetUsages.map((item) {
        return {
          'category_name': item.budget.categoryName ?? 'Kategori',
          'budget_limit': item.budget.limitAmount,
          'spent': item.spent,
          'usage_ratio': item.percent,
        };
      }).toList(),
      'goals': input.goals.map((goal) {
        return {
          'name': goal.name,
          'target_amount': goal.targetAmount,
          'saved_amount': goal.savedAmount,
          'remaining_amount': goal.remainingAmount,
          'target_date': AppDateUtils.dayMonthYear(goal.targetDate),
          'required_monthly_saving': goal.suggestedMonthlySaving,
          'months_remaining': goal.monthsRemaining,
        };
      }).toList(),
      'recent_transactions': input.recentTransactions.take(40).map((item) {
        return {
          'date': AppDateUtils.dayMonthYear(item.date),
          'type': item.type == TransactionType.income ? 'income' : 'expense',
          'amount': item.amount,
          'category': item.categoryName ?? 'Kategori',
          'note': item.note ?? '',
        };
      }).toList(),
      'output_requirements': {
        'language': 'Indonesian',
        'max_advices': 8,
        'json_schema': {
          'projected_balance': 'number',
          'summary': 'string',
          'advices': [
            {
              'title': 'string',
              'description': 'string',
              'level': 'positive|warning|danger|info',
            },
          ],
        },
      },
    };
  }

  Map<String, dynamic> _decodeJsonFromText(String raw) {
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
    } catch (_) {
      // fallback below
    }

    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const FormatException('Format respons AI bukan JSON.');
    }
    final sliced = raw.substring(start, end + 1);
    final parsed = jsonDecode(sliced);
    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('JSON respons AI tidak valid.');
    }
    return parsed;
  }

  AiAdviceLevel _parseLevel(String raw) {
    switch (raw.toLowerCase()) {
      case 'positive':
        return AiAdviceLevel.positive;
      case 'warning':
        return AiAdviceLevel.warning;
      case 'danger':
        return AiAdviceLevel.danger;
      case 'info':
      default:
        return AiAdviceLevel.info;
    }
  }
}

const String _systemPrompt = '''
Anda adalah penasihat keuangan pribadi berbahasa Indonesia.
Tugas Anda: menganalisis data keuangan pengguna dan menghasilkan rekomendasi yang spesifik, dapat ditindaklanjuti, dan realistis.

Aturan output:
1) Keluarkan HANYA JSON valid, tanpa markdown.
2) Gunakan struktur:
{
  "projected_balance": number,
  "summary": string,
  "advices": [
    {
      "title": string,
      "description": string,
      "level": "positive" | "warning" | "danger" | "info"
    }
  ]
}
3) Maksimal 8 advice.
4) Advice harus konkret, menyebut angka saat relevan, dan fokus pada pengeluaran, anggaran, cashflow, serta goal.
5) Jangan memberikan disclaimer panjang.
''';
