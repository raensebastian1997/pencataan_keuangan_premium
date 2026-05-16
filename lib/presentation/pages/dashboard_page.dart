import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/services/financial_notification_service.dart';
import '../../core/utils/color_utils.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/utils/material_icon_resolver.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/report_data.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_type.dart';
import '../../injection_container.dart';
import '../cubits/advisor_cubit.dart';
import '../cubits/category_cubit.dart';
import '../cubits/cubit_status.dart';
import '../cubits/dashboard_cubit.dart';
import '../cubits/transaction_cubit.dart';
import 'transactions_page.dart';
import '../widgets/chart_widgets.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    final history = await sl<FinancialNotificationService>()
        .getNotificationHistory();
    if (mounted) {
      setState(() => _notificationCount = history.length);
    }
  }

  Future<void> _openCategoryTransactions(
    BuildContext context,
    FinanceCategory category,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(
              'Transaksi ${category.name}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
          ),
          body: TransactionsPage(
            initialCategoryId: category.id,
            initialPeriod: 'all',
          ),
        ),
      ),
    );
  }

  Future<void> _openAllCategoryTransactions(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TransactionsPage(initialPeriod: 'all')),
    );
  }

  Future<void> _openNotificationHistory(BuildContext context) async {
    final history = await sl<FinancialNotificationService>()
        .getNotificationHistory();
    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _NotificationHistorySheet(items: history),
    );
    await _loadNotificationCount();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final dashboardCubit = context.read<DashboardCubit>();
        final advisorCubit = context.read<AdvisorCubit>();
        final transactionCubit = context.read<TransactionCubit>();
        await dashboardCubit.loadDashboard();
        await advisorCubit.generateAdvice();
        await transactionCubit.loadTransactions();
      },
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, dashboard) {
          final advisorState = context.watch<AdvisorCubit>().state;
          final transactionState = context.watch<TransactionCubit>().state;
          final categoryState = context.watch<CategoryCubit>().state;
          final recentTransactions = transactionState.transactions
              .take(5)
              .toList();
          final expenseCategories = categoryState.categories
              .where((item) => item.type == TransactionType.expense)
              .toList();
          final hasMoreShortcut = expenseCategories.length >= 4;
          final quickCategories = hasMoreShortcut
              ? expenseCategories.take(3).toList()
              : expenseCategories.take(4).toList();

          return MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView(
              children: [
                _HeroCard(
                  balance: dashboard.netBalance,
                  income: dashboard.totalIncome,
                  expense: dashboard.totalExpense,
                  notificationCount: _notificationCount,
                  onOpenNotifications: () => _openNotificationHistory(context),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    children: [
                      _QuickFeatureCard(
                        categories: quickCategories,
                        onTapCategory: (category) =>
                            _openCategoryTransactions(context, category),
                        showMoreShortcut: hasMoreShortcut,
                        onTapMore: () => _openAllCategoryTransactions(context),
                      ),
                      const SizedBox(height: 14),
                      _InsightBanner(advisorState: advisorState),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Recent Transactions',
                        trailing: 'See all',
                        child: _RecentTransactionList(
                          items: recentTransactions,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Budget Progress',
                        child: _BudgetPreview(usages: dashboard.budgetUsages),
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Kategori Pengeluaran',
                        child: ExpensePieChart(
                          items: dashboard.expenseByCategory,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Pemasukan vs Pengeluaran',
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: MonthlyBarChart(
                            items: dashboard.monthlyComparison,
                          ),
                        ),
                      ),
                      const SizedBox(height: 204),
                    ],
                  ),
                ),
                if (dashboard.status == CubitStatus.loading) ...[
                  const SizedBox(height: 14),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotificationHistorySheet extends StatelessWidget {
  const _NotificationHistorySheet({required this.items});

  final List<FinancialNotificationHistoryItem> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 14),
              child: Text(
                'Riwayat Notifikasi',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada notifikasi.',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        16 + bottomPadding,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isDanger = item.payload == 'negative_balance';
                        final iconColor = isDanger
                            ? scheme.error
                            : scheme.primary;
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withValues(
                              alpha: 0.55,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isDanger
                                    ? Icons.warning_amber_rounded
                                    : Icons.notifications_rounded,
                                color: iconColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      item.body,
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      DateFormat(
                                        'dd MMM yyyy, HH:mm',
                                        'id_ID',
                                      ).format(item.createdAt),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatefulWidget {
  const _HeroCard({
    required this.balance,
    required this.income,
    required this.expense,
    required this.notificationCount,
    required this.onOpenNotifications,
  });

  final double balance;
  final double income;
  final double expense;
  final int notificationCount;
  final VoidCallback onOpenNotifications;

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> {
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final gradientStart = isDark
        ? Color.lerp(scheme.surfaceContainerHighest, scheme.primary, 0.40)!
        : const Color(0xFF299DDB);
    final gradientMid = isDark
        ? Color.lerp(scheme.surfaceContainerHigh, scheme.primary, 0.58)!
        : const Color(0xFF57B4E2);
    final gradientEnd = isDark
        ? Color.lerp(
            scheme.surfaceContainerHigh,
            scheme.primaryContainer,
            0.35,
          )!
        : const Color(0xFF86D0EE);
    final onHero = Colors.white;
    final onHeroMuted = onHero.withValues(alpha: 0.86);

    final displayedBalance = _isBalanceVisible
        ? CurrencyFormatter.format(widget.balance)
        : 'Rp ••••••••';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 0.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.transparent,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStart, gradientMid, gradientEnd],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFFFFFFF),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'NoteUang Me',
                style: TextStyle(
                  color: onHero,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Material(
                color: onHero.withValues(alpha: isDark ? 0.12 : 0.20),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: widget.onOpenNotifications,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: onHero,
                        ),
                      ),
                      if (widget.notificationCount > 0)
                        Positioned(
                          right: -2,
                          top: -3,
                          child: _NotificationBadge(
                            count: widget.notificationCount,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Total Balance',
            style: TextStyle(
              fontSize: 15,
              color: onHeroMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayedBalance,
                    style: TextStyle(
                      color: onHero,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isBalanceVisible = !_isBalanceVisible;
                  });
                },
                splashRadius: 20,
                icon: Icon(
                  _isBalanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: onHero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Income',
                  value: CurrencyFormatter.format(widget.income),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Expense',
                  value: CurrencyFormatter.format(widget.expense),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ActionPill(isDark: isDark),
        ],
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white, width: 1.4),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final panelColor = isDark
        ? Colors.black.withValues(alpha: 0.17)
        : Colors.white.withValues(alpha: 0.16);
    final labelColor = Colors.white.withValues(alpha: isDark ? 0.82 : 0.88);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final backgroundColor = isDark
        ? scheme.surfaceContainerHigh.withValues(alpha: 0.94)
        : Colors.white;
    final textColor = isDark ? scheme.onSurface : const Color(0xFF10141F);
    final centerGradient = isDark
        ? [Color.lerp(scheme.primary, Colors.white, 0.22)!, scheme.primary]
        : const [Color(0xFF4CC4F6), Color(0xFF1796E7)];

    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(31),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Receive',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.call_received_rounded, color: textColor),
                ],
              ),
            ),
          ),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: centerGradient),
            ),
            child: const Icon(
              Icons.content_paste_search_sharp,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Send',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.call_made_rounded, color: textColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickFeatureCard extends StatelessWidget {
  const _QuickFeatureCard({
    required this.categories,
    required this.onTapCategory,
    required this.showMoreShortcut,
    required this.onTapMore,
  });

  final List<FinanceCategory> categories;
  final ValueChanged<FinanceCategory> onTapCategory;
  final bool showMoreShortcut;
  final VoidCallback onTapMore;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Belum ada kategori pengeluaran untuk ditampilkan.'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ...categories.map(
              (item) => _FeatureItem(
                iconCodePoint: item.iconCodePoint,
                label: item.name,
                onTap: () => onTapCategory(item),
              ),
            ),
            if (showMoreShortcut)
              _FeatureItem(
                iconCodePoint: Icons.more_horiz.codePoint,
                label: 'More',
                onTap: onTapMore,
              ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.iconCodePoint,
    required this.label,
    required this.onTap,
  });

  final int iconCodePoint;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFF4F6F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                MaterialIconResolver.fromCodePoint(iconCodePoint),
                size: 25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightBanner extends StatelessWidget {
  const _InsightBanner({required this.advisorState});

  final AdvisorState advisorState;

  void _openInsightDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AdvisorInsightDetailPage(advisorState: advisorState),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final advice = advisorState.advices.isEmpty
        ? null
        : advisorState.advices.first;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _openInsightDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF49C2F5), Color(0xFF1498EA)],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saran Keuangan Hari Ini',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      advice?.description ??
                          'Belum ada insight. Tambahkan transaksi agar analisis lebih presisi.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lihat analisa lengkap',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      advisorState.analysisEngine,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvisorInsightDetailPage extends StatelessWidget {
  const _AdvisorInsightDetailPage({required this.advisorState});

  final AdvisorState advisorState;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final advices = [...advisorState.advices]
      ..sort(
        (a, b) => _priorityValue(a.level).compareTo(_priorityValue(b.level)),
      );
    final positiveCount = advisorState.advices
        .where((item) => item.level == AdviceLevel.positive)
        .length;
    final warningCount = advisorState.advices
        .where((item) => item.level == AdviceLevel.warning)
        .length;
    final dangerCount = advisorState.advices
        .where((item) => item.level == AdviceLevel.danger)
        .length;
    final infoCount = advisorState.advices
        .where((item) => item.level == AdviceLevel.info)
        .length;
    final projectedPositive = advisorState.projectedBalance >= 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Analisa Nasihat Keuangan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(scheme.primary, scheme.surfaceTint, 0.10)!,
                  Color.lerp(scheme.primary, scheme.primaryContainer, 0.35)!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Proyeksi Saldo Bulan Depan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: Text(
                    advisorState.analysisEngine,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.format(advisorState.projectedBalance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 33,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  projectedPositive
                      ? 'Tren kas positif. Pertahankan disiplin alokasi tabungan dan anggaran.'
                      : 'Tren kas menurun. Fokus menurunkan pengeluaran non-prioritas agar saldo kembali sehat.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.94),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Diperbarui ${AppDateUtils.dayMonthYear(DateTime.now())}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InsightStatTile(
                  label: 'Positif',
                  count: positiveCount,
                  color: const Color(0xFF1EA65A),
                  icon: Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InsightStatTile(
                  label: 'Waspada',
                  count: warningCount,
                  color: const Color(0xFFF4A621),
                  icon: Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InsightStatTile(
                  label: 'Kritis',
                  count: dangerCount,
                  color: const Color(0xFFE44F4F),
                  icon: Icons.error_outline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InsightStatTile(
                  label: 'Info',
                  count: infoCount,
                  color: const Color(0xFF3A8EE6),
                  icon: Icons.info_outline_rounded,
                ),
              ),
            ],
          ),
          if ((advisorState.message ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: scheme.surfaceContainerHighest,
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      advisorState.message!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Detail Analisa',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (advices.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: scheme.surfaceContainerHigh,
              ),
              child: const Text(
                'Belum ada insight. Tambahkan transaksi agar analisa menjadi lebih akurat.',
              ),
            )
          else
            ...advices.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final advice = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AdviceDetailTile(index: index, advice: advice),
              );
            }),
        ],
      ),
    );
  }
}

int _priorityValue(AdviceLevel level) {
  switch (level) {
    case AdviceLevel.danger:
      return 0;
    case AdviceLevel.warning:
      return 1;
    case AdviceLevel.info:
      return 2;
    case AdviceLevel.positive:
      return 3;
  }
}

class _AdviceDetailTile extends StatelessWidget {
  const _AdviceDetailTile({required this.index, required this.advice});

  final int index;
  final AdviceItem advice;

  @override
  Widget build(BuildContext context) {
    final style = _adviceLevelVisual(advice.level);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.surface,
        border: Border.all(color: style.color.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: style.color.withValues(alpha: 0.16),
            ),
            child: Icon(style.icon, color: style.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        advice.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: style.color.withValues(alpha: 0.14),
                      ),
                      child: Text(
                        '${style.label} #$index',
                        style: TextStyle(
                          color: style.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  advice.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.35,
                    color: scheme.onSurface.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightStatTile extends StatelessWidget {
  const _InsightStatTile({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surface,
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.74),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdviceLevelVisual {
  const _AdviceLevelVisual({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;
}

_AdviceLevelVisual _adviceLevelVisual(AdviceLevel level) {
  switch (level) {
    case AdviceLevel.positive:
      return const _AdviceLevelVisual(
        color: Color(0xFF1EA65A),
        icon: Icons.trending_up_rounded,
        label: 'Positif',
      );
    case AdviceLevel.warning:
      return const _AdviceLevelVisual(
        color: Color(0xFFF4A621),
        icon: Icons.warning_amber_rounded,
        label: 'Waspada',
      );
    case AdviceLevel.danger:
      return const _AdviceLevelVisual(
        color: Color(0xFFE44F4F),
        icon: Icons.error_outline_rounded,
        label: 'Kritis',
      );
    case AdviceLevel.info:
      return const _AdviceLevelVisual(
        color: Color(0xFF3A8EE6),
        icon: Icons.info_outline_rounded,
        label: 'Info',
      );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (trailing != null) ...[
                    const Spacer(),
                    Text(
                      trailing!,
                      style: const TextStyle(
                        color: Color(0xFF586476),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTransactionList extends StatelessWidget {
  const _RecentTransactionList({required this.items});

  final List<FinancialTransaction> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text('Belum ada transaksi.'),
      );
    }

    return Column(
      children: items.map((item) {
        final isIncome = item.type == TransactionType.income;
        final categoryColor = ColorUtils.fromHex(
          item.categoryColorHex ?? '#2BA9E1',
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: categoryColor.withValues(alpha: 0.14),
                child: Icon(
                  MaterialIconResolver.fromCodePoint(
                    item.categoryIconCodePoint ?? Icons.category.codePoint,
                  ),
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.categoryName ?? 'Kategori',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      '${isIncome ? 'Pemasukan' : 'Pengeluaran'} • ${AppDateUtils.dayMonthYear(item.date)}',
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'}${CurrencyFormatter.format(item.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isIncome
                      ? const Color(0xFF12A150)
                      : const Color(0xFF171A22),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _BudgetPreview extends StatelessWidget {
  const _BudgetPreview({required this.usages});

  final List<BudgetUsage> usages;

  @override
  Widget build(BuildContext context) {
    if (usages.isEmpty) {
      return const Text('Belum ada anggaran bulan ini.');
    }

    return Column(
      children: usages.take(3).map((usage) {
        final percent = usage.percent.clamp(0, 1).toDouble();
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      usage.budget.categoryName ?? 'Kategori',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${(usage.percent * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 9,
                  backgroundColor: const Color(0xFFE8EDF3),
                  color: usage.percent > 1
                      ? const Color(0xFFE94848)
                      : usage.percent > 0.8
                      ? const Color(0xFFF4A621)
                      : const Color(0xFF1B9DEB),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
