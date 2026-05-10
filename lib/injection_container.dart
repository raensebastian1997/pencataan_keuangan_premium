import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'data/datasources/ai_advisor_remote_datasource.dart';
import 'data/datasources/local_database.dart';
import 'data/repositories/advisor_ai_repository_impl.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/budget_repository_impl.dart';
import 'data/repositories/category_repository_impl.dart';
import 'data/repositories/goal_repository_impl.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'domain/repositories/advisor_ai_repository.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/budget_repository.dart';
import 'domain/repositories/category_repository.dart';
import 'domain/repositories/goal_repository.dart';
import 'domain/repositories/transaction_repository.dart';
import 'presentation/cubits/advisor_cubit.dart';
import 'presentation/cubits/auth_cubit.dart';
import 'presentation/cubits/budget_cubit.dart';
import 'presentation/cubits/category_cubit.dart';
import 'presentation/cubits/dashboard_cubit.dart';
import 'presentation/cubits/goal_cubit.dart';
import 'presentation/cubits/settings_cubit.dart';
import 'presentation/cubits/transaction_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  final prefs = await SharedPreferences.getInstance();

  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<http.Client>(() => http.Client());
  sl.registerLazySingleton<LocalDatabase>(() => LocalDatabase());
  sl.registerLazySingleton<AiAdvisorRemoteDataSource>(
    () => AiAdvisorRemoteDataSource(sl()),
  );
  await sl<LocalDatabase>().database;

  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<BudgetRepository>(() => BudgetRepositoryImpl(sl()));
  sl.registerLazySingleton<GoalRepository>(() => GoalRepositoryImpl(sl()));
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<AdvisorAiRepository>(
    () => AdvisorAiRepositoryImpl(sl()),
  );

  sl.registerFactory(() => AuthCubit(sl()));
  sl.registerFactory(() => SettingsCubit(sl()));
  sl.registerFactory(() => CategoryCubit(sl()));
  sl.registerFactory(() => TransactionCubit(sl(), sl()));
  sl.registerFactory(() => BudgetCubit(sl(), sl(), sl()));
  sl.registerFactory(() => GoalCubit(sl()));
  sl.registerFactory(() => DashboardCubit(sl(), sl(), sl()));
  sl.registerFactory(() => AdvisorCubit(sl(), sl(), sl(), sl(), sl(), sl()));
}
