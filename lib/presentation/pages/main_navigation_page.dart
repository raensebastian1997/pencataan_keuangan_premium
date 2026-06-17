import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/advisor_cubit.dart';
import '../cubits/budget_cubit.dart';
import '../cubits/dashboard_cubit.dart';
import '../cubits/goal_cubit.dart';
import '../cubits/transaction_cubit.dart';
import 'budgets_page.dart';
import 'dashboard_page.dart';
import 'goals_page.dart';
import 'settings_page.dart';
import 'transaction_form_page.dart';
import 'transactions_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  final _pages = const [
    DashboardPage(),
    TransactionsPage(),
    BudgetsPage(),
    // GoalsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(index: _selectedIndex, children: _pages),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 10,
            child: _FloatingBottomBar(
              selectedIndex: _selectedIndex,
              onSelected: (index) {
                setState(() => _selectedIndex = index);
                _refreshCurrentTab();
              },
              onAddTransaction: _openQuickTransactionForm,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openQuickTransactionForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransactionFormPage()),
    );
    if (!mounted) {
      return;
    }
    _refreshCurrentTab();
    await context.read<DashboardCubit>().loadDashboard();
    await context.read<AdvisorCubit>().generateAdvice();
    await context.read<BudgetCubit>().loadMonth(
      context.read<BudgetCubit>().state.month,
    );
  }

  void _refreshCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        context.read<DashboardCubit>().loadDashboard();
        context.read<AdvisorCubit>().generateAdvice();
      case 1:
        context.read<TransactionCubit>().loadTransactions();
      case 2:
        context.read<BudgetCubit>().loadMonth(
          context.read<BudgetCubit>().state.month,
        );
      case 3:
        context.read<GoalCubit>().loadGoals();
        context.read<AdvisorCubit>().generateAdvice();
      case 4:
        break;
    }
  }
}

class _FloatingBottomBar extends StatelessWidget {
  const _FloatingBottomBar({
    required this.selectedIndex,
    required this.onSelected,
    required this.onAddTransaction,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onAddTransaction;

  @override
  Widget build(BuildContext context) {
    const inactiveColor = Color(0xFFA3ACBA);
    return SafeArea(
      top: false,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF161A23),
          borderRadius: BorderRadius.circular(36),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavItem(
              selected: selectedIndex == 0,
              icon: Icons.home_rounded,
              onTap: () => onSelected(0),
            ),
            _NavItem(
              selected: selectedIndex == 1,
              icon: Icons.show_chart_rounded,
              onTap: () => onSelected(1),
            ),
            GestureDetector(
              onTap: onAddTransaction,
              child: Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF4CC4F6), Color(0xFF1796E7)],
                  ),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            IconButton(
              onPressed: () => onSelected(2),
              icon: Icon(
                Icons.account_balance_wallet_rounded,
                color: selectedIndex == 2 ? Colors.white : inactiveColor,
              ),
            ),
            // IconButton(
            //   onPressed: () => onSelected(3),
            //   icon: Icon(
            //     Icons.flag_rounded,
            //     color: selectedIndex == 3 ? Colors.white : inactiveColor,
            //   ),
            // ),
            IconButton(
              onPressed: () => onSelected(4),
              icon: Icon(
                Icons.person_rounded,
                color: selectedIndex == 4 ? Colors.white : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF37BAF4), Color(0xFF1498EA)],
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      );
    }

    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: const Color(0xFFA3ACBA)),
    );
  }
}
