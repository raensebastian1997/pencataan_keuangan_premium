import '../../domain/entities/ai_analysis.dart';
import '../../domain/repositories/advisor_ai_repository.dart';
import '../datasources/ai_advisor_remote_datasource.dart';

class AdvisorAiRepositoryImpl implements AdvisorAiRepository {
  const AdvisorAiRepositoryImpl(this._remoteDataSource);

  final AiAdvisorRemoteDataSource _remoteDataSource;

  @override
  Future<AiAnalysisOutput> generateFinancialAnalysis({
    required String apiKey,
    required String model,
    required AiAnalysisInput input,
  }) {
    return _remoteDataSource.generateFinancialAnalysis(
      apiKey: apiKey,
      model: model,
      input: input,
    );
  }
}
