import '../entities/ai_analysis.dart';

abstract class AdvisorAiRepository {
  Future<AiAnalysisOutput> generateFinancialAnalysis({
    required String apiKey,
    required String model,
    required AiAnalysisInput input,
  });
}
