import 'dart:io';

import 'package:excel/excel.dart' as xlsx;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/color_utils.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/utils/material_icon_resolver.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_type.dart';
import '../cubits/advisor_cubit.dart';
import '../cubits/budget_cubit.dart';
import '../cubits/cubit_status.dart';
import '../cubits/dashboard_cubit.dart';
import '../cubits/transaction_cubit.dart';
import 'transaction_form_page.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({
    super.key,
    this.initialCategoryId,
    this.initialPeriod,
  });

  final int? initialCategoryId;
  final String? initialPeriod;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _period = 'this_month';
  int? _categoryId;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    if (widget.initialPeriod != null) {
      _period = widget.initialPeriod!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyFilters());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      child: BlocConsumer<TransactionCubit, TransactionState>(
        listener: (context, state) {
          if (state.status == CubitStatus.failure && state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          final transactions = state.transactions;
          final totalIncome = _sumByType(transactions, TransactionType.income);
          final totalExpense = _sumByType(
            transactions,
            TransactionType.expense,
          );
          final netBalance = totalIncome - totalExpense;
          final selectedCategory = _selectedCategory(state.categories);
          final listChildren = _buildTransactionSections(transactions);

          return RefreshIndicator(
            onRefresh: _refreshCurrentView,
            child: Stack(
              children: [
                ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    _TransactionsHero(
                      filterLabel: _filterLabel(state.categories),
                      transactionCount: transactions.length,
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                      netBalance: netBalance,
                      selectedCategory: selectedCategory,
                      onFilterTap: () => _openFilterSheet(state.categories),
                      onShareTap: () => _shareExcelReport(
                        transactions: transactions,
                        filterLabel: _filterLabel(state.categories),
                        totalIncome: totalIncome,
                        totalExpense: totalExpense,
                        netBalance: netBalance,
                      ),
                      onAddTap: () => _openForm(),
                      onScanTap: () => _openForm(startWithOcr: true),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                      child: _PeriodSelector(
                        selectedPeriod: _period,
                        onSelected: _selectPeriod,
                      ),
                    ),
                    if (state.categories.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _CategoryScroller(
                        categories: state.categories,
                        selectedCategoryId: _categoryId,
                        onSelected: _selectCategory,
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                      child: _ListHeader(
                        title: 'Riwayat Transaksi',
                        subtitle: '${transactions.length} transaksi ditemukan',
                        onFilterTap: () => _openFilterSheet(state.categories),
                      ),
                    ),
                    if (transactions.isEmpty)
                      _EmptyTransactions(onAddTap: () => _openForm())
                    else
                      ...listChildren,
                    const SizedBox(height: 120),
                  ],
                ),
                if (state.status == CubitStatus.loading)
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  double _sumByType(
    List<FinancialTransaction> transactions,
    TransactionType type,
  ) {
    return transactions
        .where((transaction) => transaction.type == type)
        .fold<double>(0, (total, transaction) => total + transaction.amount);
  }

  FinanceCategory? _selectedCategory(List<FinanceCategory> categories) {
    return categories.where((item) => item.id == _categoryId).firstOrNull;
  }

  List<Widget> _buildTransactionSections(
    List<FinancialTransaction> transactions,
  ) {
    final children = <Widget>[];
    DateTime? activeDate;

    for (final transaction in transactions) {
      if (activeDate == null || !_isSameDay(activeDate, transaction.date)) {
        activeDate = transaction.date;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: _DateSectionHeader(date: transaction.date),
          ),
        );
      }
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: _PremiumTransactionTile(
            transaction: transaction,
            onTap: () => _showTransactionDetail(transaction),
            onEdit: () => _openForm(transaction: transaction),
            onDelete: () => _confirmDelete(transaction.id),
          ),
        ),
      );
    }

    return children;
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _filterLabel(List<FinanceCategory> categories) {
    final periodLabel = _periodLabel(_period);
    final category = categories
        .where((item) => item.id == _categoryId)
        .firstOrNull;
    return category == null ? periodLabel : '$periodLabel - ${category.name}';
  }

  String _periodLabel(String period) {
    return switch (period) {
      'last_month' => 'Bulan lalu',
      'custom' =>
        _customRange == null
            ? 'Rentang custom'
            : '${AppDateUtils.dayMonthYear(_customRange!.start)} - '
                  '${AppDateUtils.dayMonthYear(_customRange!.end)}',
      'all' => 'Semua transaksi',
      _ => 'Bulan ini',
    };
  }

  Future<void> _selectPeriod(String period) async {
    var selectedRange = _customRange;
    if (period == 'custom') {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(DateTime.now().year + 5),
        initialDateRange: selectedRange,
      );
      if (picked == null || !mounted) {
        return;
      }
      selectedRange = picked;
    }

    setState(() {
      _period = period;
      _customRange = period == 'custom' ? selectedRange : _customRange;
    });
    await _applyFilters();
  }

  Future<void> _selectCategory(int? categoryId) async {
    setState(() => _categoryId = categoryId);
    await _applyFilters();
  }

  Future<void> _openFilterSheet(List<FinanceCategory> categories) async {
    var selectedPeriod = _period;
    var selectedCategoryId = _categoryId;
    var selectedRange = _customRange;

    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickRange() async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(DateTime.now().year + 5),
                initialDateRange: selectedRange,
              );
              if (picked != null && context.mounted) {
                setSheetState(() {
                  selectedPeriod = 'custom';
                  selectedRange = picked;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SheetHeader(
                      title: 'Filter Transaksi',
                      subtitle: 'Pilih periode dan kategori transaksi.',
                    ),
                    const SizedBox(height: 16),
                    const _SheetSectionLabel('Periode'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _FilterChoiceChip(
                          label: 'Bulan ini',
                          icon: Icons.calendar_today_rounded,
                          selected: selectedPeriod == 'this_month',
                          onTap: () => setSheetState(
                            () => selectedPeriod = 'this_month',
                          ),
                        ),
                        _FilterChoiceChip(
                          label: 'Bulan lalu',
                          icon: Icons.history_rounded,
                          selected: selectedPeriod == 'last_month',
                          onTap: () => setSheetState(
                            () => selectedPeriod = 'last_month',
                          ),
                        ),
                        _FilterChoiceChip(
                          label: 'Custom',
                          icon: Icons.date_range_rounded,
                          selected: selectedPeriod == 'custom',
                          onTap: pickRange,
                        ),
                        _FilterChoiceChip(
                          label: 'Semua',
                          icon: Icons.all_inclusive_rounded,
                          selected: selectedPeriod == 'all',
                          onTap: () =>
                              setSheetState(() => selectedPeriod = 'all'),
                        ),
                      ],
                    ),
                    if (selectedPeriod == 'custom') ...[
                      const SizedBox(height: 12),
                      _SelectedRangeCard(
                        range: selectedRange,
                        onTap: pickRange,
                      ),
                    ],
                    const SizedBox(height: 20),
                    const _SheetSectionLabel('Kategori'),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _FilterChoiceChip(
                              label: 'Semua kategori',
                              icon: Icons.grid_view_rounded,
                              selected: selectedCategoryId == null,
                              onTap: () => setSheetState(
                                () => selectedCategoryId = null,
                              ),
                            ),
                            ...categories.map(
                              (category) => _FilterChoiceChip(
                                label: category.name,
                                icon: MaterialIconResolver.fromCodePoint(
                                  category.iconCodePoint,
                                ),
                                selected: selectedCategoryId == category.id,
                                color: ColorUtils.fromHex(category.colorHex),
                                onTap: () => setSheetState(
                                  () => selectedCategoryId = category.id,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(
                              context,
                              const _FilterResult(
                                period: 'this_month',
                                categoryId: null,
                                customRange: null,
                              ),
                            ),
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: () async {
                              if (selectedPeriod == 'custom' &&
                                  selectedRange == null) {
                                await pickRange();
                                if (selectedRange == null || !context.mounted) {
                                  return;
                                }
                              }
                              if (!context.mounted) {
                                return;
                              }
                              Navigator.pop(
                                context,
                                _FilterResult(
                                  period: selectedPeriod,
                                  categoryId: selectedCategoryId,
                                  customRange: selectedRange,
                                ),
                              );
                            },
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Terapkan Filter'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _period = result.period;
      _categoryId = result.categoryId;
      _customRange = result.customRange;
    });
    await _applyFilters();
  }

  Future<void> _refreshCurrentView() async {
    await _applyFilters();
  }

  Future<void> _shareExcelReport({
    required List<FinancialTransaction> transactions,
    required String filterLabel,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
  }) async {
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada transaksi untuk dibagikan.')),
      );
      return;
    }

    try {
      final file = await _createExcelReport(
        transactions: transactions,
        filterLabel: filterLabel,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netBalance: netBalance,
      );
      await SharePlus.instance.share(
        ShareParams(
          title: 'Bagikan report keuangan',
          subject: 'Report Keuangan NoteUang Me',
          text: 'Report keuangan NoteUang Me - $filterLabel',
          files: [
            XFile(
              file.path,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat report Excel: $error')),
      );
    }
  }

  Future<File> _createExcelReport({
    required List<FinancialTransaction> transactions,
    required String filterLabel,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
  }) async {
    final excel = xlsx.Excel.createExcel();
    excel.rename('Sheet1', 'Report');
    final sheet = excel['Report'];

    sheet.appendRow([xlsx.TextCellValue('Report Keuangan NoteUang Me')]);
    sheet.appendRow([
      xlsx.TextCellValue('Periode'),
      xlsx.TextCellValue(filterLabel),
    ]);
    sheet.appendRow([
      xlsx.TextCellValue('Dibuat'),
      xlsx.TextCellValue(
        DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(DateTime.now()),
      ),
    ]);
    sheet.appendRow([]);
    sheet.appendRow([
      xlsx.TextCellValue('Total Pemasukan'),
      xlsx.DoubleCellValue(totalIncome),
    ]);
    sheet.appendRow([
      xlsx.TextCellValue('Total Pengeluaran'),
      xlsx.DoubleCellValue(totalExpense),
    ]);
    sheet.appendRow([
      xlsx.TextCellValue('Saldo Bersih'),
      xlsx.DoubleCellValue(netBalance),
    ]);
    sheet.appendRow([]);
    sheet.appendRow([
      xlsx.TextCellValue('Tanggal'),
      xlsx.TextCellValue('Jenis'),
      xlsx.TextCellValue('Kategori'),
      xlsx.TextCellValue('Nominal'),
      xlsx.TextCellValue('Catatan'),
    ]);

    for (final transaction in transactions) {
      sheet.appendRow([
        xlsx.TextCellValue(
          DateFormat('dd MMM yyyy', 'id_ID').format(transaction.date),
        ),
        xlsx.TextCellValue(transaction.type.label),
        xlsx.TextCellValue(transaction.categoryName ?? '-'),
        xlsx.DoubleCellValue(
          transaction.type == TransactionType.income
              ? transaction.amount
              : -transaction.amount,
        ),
        xlsx.TextCellValue((transaction.note ?? '').trim()),
      ]);
    }

    sheet
      ..setColumnWidth(0, 16)
      ..setColumnWidth(1, 16)
      ..setColumnWidth(2, 24)
      ..setColumnWidth(3, 18)
      ..setColumnWidth(4, 36);

    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Gagal menyimpan workbook.');
    }

    final directory = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/report_keuangan_$timestamp.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _applyFilters() {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end;
    switch (_period) {
      case 'last_month':
        start = AppDateUtils.startOfPreviousMonth(now);
        end = AppDateUtils.endOfPreviousMonth(now);
      case 'custom':
        start = _customRange?.start;
        end = _customRange == null
            ? null
            : DateTime(
                _customRange!.end.year,
                _customRange!.end.month,
                _customRange!.end.day,
                23,
                59,
                59,
              );
      case 'all':
        start = null;
        end = null;
      default:
        start = AppDateUtils.startOfMonth(now);
        end = AppDateUtils.endOfMonth(now);
    }
    return context.read<TransactionCubit>().loadTransactions(
      startDate: start,
      endDate: end,
      categoryId: _categoryId,
      clearFilters: _period == 'all' && _categoryId == null,
    );
  }

  Future<void> _openForm({
    FinancialTransaction? transaction,
    bool startWithOcr = false,
  }) async {
    final dashboardCubit = context.read<DashboardCubit>();
    final advisorCubit = context.read<AdvisorCubit>();
    final budgetCubit = context.read<BudgetCubit>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionFormPage(
          transaction: transaction,
          startWithOcr: startWithOcr,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    await _applyFilters();
    await dashboardCubit.loadDashboard();
    await advisorCubit.generateAdvice();
    await budgetCubit.loadMonth(budgetCubit.state.month);
  }

  Future<void> _confirmDelete(int? id) async {
    if (id == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: const Text('Transaksi yang dihapus tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final transactionCubit = context.read<TransactionCubit>();
    final dashboardCubit = context.read<DashboardCubit>();
    final advisorCubit = context.read<AdvisorCubit>();
    final budgetCubit = context.read<BudgetCubit>();
    await transactionCubit.deleteTransaction(id);
    if (!mounted) {
      return;
    }
    await _applyFilters();
    await dashboardCubit.loadDashboard();
    await advisorCubit.generateAdvice();
    await budgetCubit.loadMonth(budgetCubit.state.month);
  }

  Future<void> _showTransactionDetail(FinancialTransaction transaction) {
    final isIncome = transaction.type == TransactionType.income;
    final categoryColor = ColorUtils.fromHex(
      transaction.categoryColorHex ?? '#20A7DB',
    );

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      MaterialIconResolver.fromCodePoint(
                        transaction.categoryIconCodePoint ??
                            Icons.category_rounded.codePoint,
                        fallback: Icons.category_rounded,
                      ),
                      color: categoryColor,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    '${isIncome ? '+' : '-'}'
                    '${CurrencyFormatter.format(transaction.amount)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isIncome
                          ? const Color(0xFF0C9F5B)
                          : colorScheme.onSurface,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    transaction.categoryName ?? 'Detail Transaksi',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.55,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Jenis',
                        value: isIncome ? 'Pemasukan' : 'Pengeluaran',
                      ),
                      _DetailRow(
                        label: 'Tanggal',
                        value: AppDateUtils.dayMonthYear(transaction.date),
                      ),
                      _DetailRow(
                        label: 'Kategori',
                        value: transaction.categoryName ?? '-',
                      ),
                      _DetailRow(
                        label: 'Catatan',
                        value: (transaction.note ?? '').trim().isEmpty
                            ? '-'
                            : transaction.note!,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDelete(transaction.id);
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Hapus'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openForm(transaction: transaction);
                        },
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Edit Transaksi'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TransactionsHero extends StatelessWidget {
  const _TransactionsHero({
    required this.filterLabel,
    required this.transactionCount,
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.selectedCategory,
    required this.onFilterTap,
    required this.onShareTap,
    required this.onAddTap,
    required this.onScanTap,
  });

  final String filterLabel;
  final int transactionCount;
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final FinanceCategory? selectedCategory;
  final VoidCallback onFilterTap;
  final VoidCallback onShareTap;
  final VoidCallback onAddTap;
  final VoidCallback onScanTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? colorScheme.onSurface : Colors.white;
    final mutedForeground = foreground.withValues(alpha: 0.74);

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 18,
        16,
        22,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF101820), Color(0xFF173444), Color(0xFF15616E)]
              : const [Color(0xFF25A8E0), Color(0xFF43B7D8), Color(0xFF72D9C6)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.14 : 0.2),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.receipt_long_rounded, color: foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NoteUang Me Ledger',
                      style: TextStyle(
                        color: mutedForeground,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Transaksi',
                      style: TextStyle(
                        color: foreground,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton.filled(
                    onPressed: onShareTap,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      foregroundColor: foreground,
                    ),
                    icon: const Icon(Icons.ios_share_rounded),
                    tooltip: 'Share report Excel',
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: onFilterTap,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      foregroundColor: foreground,
                    ),
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: 'Filter transaksi',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Saldo periode aktif',
            style: TextStyle(
              color: mutedForeground,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                CurrencyFormatter.format(netBalance),
                style: TextStyle(
                  color: foreground,
                  fontSize: 25,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(
                icon: Icons.filter_alt_rounded,
                label: filterLabel,
                foreground: foreground,
              ),
              _HeroPill(
                icon: Icons.format_list_numbered_rounded,
                label: '$transactionCount data',
                foreground: foreground,
              ),
              if (selectedCategory != null)
                _HeroPill(
                  icon: MaterialIconResolver.fromCodePoint(
                    selectedCategory!.iconCodePoint,
                  ),
                  label: selectedCategory!.name,
                  foreground: foreground,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.18),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _HeroMetric(
                        label: 'Pemasukan',
                        value: CurrencyFormatter.format(totalIncome),
                        icon: Icons.south_west_rounded,
                        foreground: foreground,
                        mutedForeground: mutedForeground,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HeroMetric(
                        label: 'Pengeluaran',
                        value: CurrencyFormatter.format(totalExpense),
                        icon: Icons.north_east_rounded,
                        foreground: foreground,
                        mutedForeground: mutedForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onScanTap,
                        icon: const Icon(Icons.document_scanner_rounded),
                        label: const Text('Scan Struk'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: foreground,
                          side: BorderSide(
                            color: foreground.withValues(alpha: 0.34),
                          ),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onAddTap,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Tambah'),
                        style: FilledButton.styleFrom(
                          backgroundColor: foreground,
                          textStyle: const TextStyle(fontSize: 14),
                          foregroundColor: isDark
                              ? const Color(0xFF111820)
                              : const Color(0xFF171A22),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.label,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.foreground,
    required this.mutedForeground,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color foreground;
  final Color mutedForeground;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: foreground, size: 18),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: mutedForeground,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onSelected,
  });

  final String selectedPeriod;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      _PeriodOption('this_month', 'Bulan ini', Icons.calendar_today_rounded),
      _PeriodOption('last_month', 'Bulan lalu', Icons.history_rounded),
      _PeriodOption('custom', 'Custom', Icons.date_range_rounded),
      _PeriodOption('all', 'Semua', Icons.all_inclusive_rounded),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = selectedPeriod == item.value;
          return _SegmentChip(
            label: item.label,
            icon: item.icon,
            selected: isSelected,
            onTap: () => onSelected(item.value),
          );
        },
      ),
    );
  }
}

class _PeriodOption {
  const _PeriodOption(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colorScheme.onSurface : colorScheme.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? colorScheme.onSurface
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? colorScheme.surface : colorScheme.primary,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? colorScheme.surface : colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryScroller extends StatelessWidget {
  const _CategoryScroller({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<FinanceCategory> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CategoryShortcut(
              label: 'Semua',
              icon: Icons.grid_view_rounded,
              selected: selectedCategoryId == null,
              color: Theme.of(context).colorScheme.primary,
              onTap: () => onSelected(null),
            );
          }

          final category = categories[index - 1];
          return _CategoryShortcut(
            label: category.name,
            icon: MaterialIconResolver.fromCodePoint(category.iconCodePoint),
            selected: selectedCategoryId == category.id,
            color: ColorUtils.fromHex(category.colorHex),
            onTap: () => onSelected(category.id),
          );
        },
      ),
    );
  }
}

class _CategoryShortcut extends StatelessWidget {
  const _CategoryShortcut({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 78,
      child: Material(
        color: selected
            ? color.withValues(alpha: 0.14)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? color.withValues(alpha: 0.65)
                    : colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 7),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.title,
    required this.subtitle,
    required this.onFilterTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onFilterTap,
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    );
  }
}

class _DateSectionHeader extends StatelessWidget {
  const _DateSectionHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          AppDateUtils.dayMonthYear(date),
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: colorScheme.outlineVariant)),
      ],
    );
  }
}

class _PremiumTransactionTile extends StatelessWidget {
  const _PremiumTransactionTile({
    required this.transaction,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final FinancialTransaction transaction;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isIncome = transaction.type == TransactionType.income;
    final categoryColor = ColorUtils.fromHex(
      transaction.categoryColorHex ?? '#20A7DB',
    );
    final amountColor = isIncome
        ? const Color(0xFF0C9F5B)
        : colorScheme.onSurface;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.045),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  MaterialIconResolver.fromCodePoint(
                    transaction.categoryIconCodePoint ??
                        Icons.category_rounded.codePoint,
                    fallback: Icons.category_rounded,
                  ),
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.categoryName ?? 'Kategori',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      [
                        transaction.type.label,
                        if ((transaction.note ?? '').trim().isNotEmpty)
                          transaction.note!.trim(),
                      ].join(' - '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _TransactionStatusPill(
                      isIncome: isIncome,
                      color: categoryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 132,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PopupMenuButton<_TransactionMenuAction>(
                      tooltip: 'Aksi transaksi',
                      onSelected: (action) {
                        switch (action) {
                          case _TransactionMenuAction.edit:
                            onEdit();
                          case _TransactionMenuAction.delete:
                            onDelete();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _TransactionMenuAction.edit,
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: _TransactionMenuAction.delete,
                          child: Text('Hapus'),
                        ),
                      ],
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${isIncome ? '+' : '-'}'
                          '${CurrencyFormatter.format(transaction.amount)}',
                          maxLines: 1,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: amountColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionStatusPill extends StatelessWidget {
  const _TransactionStatusPill({required this.isIncome, required this.color});

  final bool isIncome;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final statusColor = isIncome ? const Color(0xFF0C9F5B) : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isIncome ? 'Masuk' : 'Tercatat',
        style: TextStyle(
          color: statusColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

enum _TransactionMenuAction { edit, delete }

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({required this.onAddTap});

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 36,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada transaksi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Tambahkan transaksi baru atau ubah filter untuk melihat data lain.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Transaksi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.tune_rounded, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetSectionLabel extends StatelessWidget {
  const _SheetSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
    );
  }
}

class _FilterChoiceChip extends StatelessWidget {
  const _FilterChoiceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = color ?? colorScheme.primary;
    return Material(
      color: selected
          ? activeColor.withValues(alpha: 0.14)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? activeColor.withValues(alpha: 0.65)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: activeColor),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedRangeCard extends StatelessWidget {
  const _SelectedRangeCard({required this.range, required this.onTap});

  final DateTimeRange? range;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = range == null
        ? 'Pilih rentang tanggal'
        : '${AppDateUtils.dayMonthYear(range!.start)} - '
              '${AppDateUtils.dayMonthYear(range!.end)}';

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.date_range_rounded, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterResult {
  const _FilterResult({
    required this.period,
    required this.categoryId,
    required this.customRange,
  });

  final String period;
  final int? categoryId;
  final DateTimeRange? customRange;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
