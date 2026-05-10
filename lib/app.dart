import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'injection_container.dart';
import 'presentation/cubits/advisor_cubit.dart';
import 'presentation/cubits/auth_cubit.dart';
import 'presentation/cubits/budget_cubit.dart';
import 'presentation/cubits/category_cubit.dart';
import 'presentation/cubits/dashboard_cubit.dart';
import 'presentation/cubits/goal_cubit.dart';
import 'presentation/cubits/settings_cubit.dart';
import 'presentation/cubits/transaction_cubit.dart';
import 'presentation/pages/auth_page.dart';
import 'presentation/pages/main_navigation_page.dart';
import 'presentation/pages/splash_page.dart';

class MoneyTrackerApp extends StatelessWidget {
  const MoneyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthCubit>()..checkAuthStatus()),
        BlocProvider(create: (_) => sl<SettingsCubit>()..loadTheme()),
        BlocProvider(create: (_) => sl<CategoryCubit>()..loadCategories()),
        BlocProvider(create: (_) => sl<TransactionCubit>()..loadTransactions()),
        BlocProvider(create: (_) => sl<BudgetCubit>()..loadCurrentMonth()),
        BlocProvider(create: (_) => sl<GoalCubit>()..loadGoals()),
        BlocProvider(create: (_) => sl<DashboardCubit>()..loadDashboard()),
        BlocProvider(create: (_) => sl<AdvisorCubit>()..generateAdvice()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: state.themeMode,
            home: const _AppEntry(),
          );
        },
      ),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  static const _minimumSplashDuration = Duration(milliseconds: 1200);

  bool _minimumSplashDone = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(_minimumSplashDuration, () {
      if (mounted) {
        setState(() => _minimumSplashDone = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (!_minimumSplashDone || authState.mode == AuthMode.checking) {
          return const SplashPage();
        }
        if (authState.isAuthenticated) {
          return const MainNavigationPage();
        }
        return const AuthPage();
      },
    );
  }
}
