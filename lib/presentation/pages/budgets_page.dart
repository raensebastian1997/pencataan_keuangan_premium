import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/report_data.dart';
import '../cubits/advisor_cubit.dart';
import '../cubits/budget_cubit.dart';
import '../cubits/cubit_status.dart';
import '../cubits/dashboard_cubit.dart';
import '../widgets/budget_bar.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BudgetCubit, BudgetState>(
      listener: (context, state) {
        if (state.status == CubitStatus.failure && state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () =>
                        context.read<BudgetCubit>().previousMonth(),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        AppDateUtils.monthYear(state.month),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => context.read<BudgetCubit>().nextMonth(),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: state.categories.isEmpty
                      ? null
                      : () => _openBudgetDialog(context, state),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Anggaran'),
                ),
              ),
            ),
            if (state.status == CubitStatus.loading)
              const LinearProgressIndicator(),
            Expanded(
              child: state.usages.isEmpty
                  ? const _EmptyBudget()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      itemCount: state.usages.length,
                      itemBuilder: (context, index) {
                        final usage = state.usages[index];
                        return BudgetBar(
                          usage: usage,
                          onEdit: () =>
                              _openBudgetDialog(context, state, usage: usage),
                          onDelete: () =>
                              _deleteBudget(context, usage.budget.id),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openBudgetDialog(
    BuildContext context,
    BudgetState state, {
    BudgetUsage? usage,
  }) async {
    final budgetCubit = context.read<BudgetCubit>();
    final dashboardCubit = context.read<DashboardCubit>();
    final advisorCubit = context.read<AdvisorCubit>();
    final budget = await showDialog<Budget>(
      context: context,
      builder: (context) => _BudgetFormDialog(
        month: state.month,
        categories: state.categories,
        existing: usage?.budget,
      ),
    );
    if (budget == null || !context.mounted) {
      return;
    }
    await budgetCubit.saveBudget(budget);
    await dashboardCubit.loadDashboard();
    await advisorCubit.generateAdvice();
  }

  Future<void> _deleteBudget(BuildContext context, int? id) async {
    if (id == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus anggaran?'),
        content: const Text(
          'Anggaran kategori ini untuk bulan terpilih akan dihapus.',
        ),
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
    if (confirmed != true || !context.mounted) {
      return;
    }
    final budgetCubit = context.read<BudgetCubit>();
    final dashboardCubit = context.read<DashboardCubit>();
    final advisorCubit = context.read<AdvisorCubit>();
    await budgetCubit.deleteBudget(id);
    await dashboardCubit.loadDashboard();
    await advisorCubit.generateAdvice();
  }
}

class _BudgetFormDialog extends StatefulWidget {
  const _BudgetFormDialog({
    required this.month,
    required this.categories,
    this.existing,
  });

  final DateTime month;
  final List<FinanceCategory> categories;
  final Budget? existing;

  @override
  State<_BudgetFormDialog> createState() => _BudgetFormDialogState();
}

class _BudgetFormDialogState extends State<_BudgetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _limitController;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _categoryId =
        widget.existing?.categoryId ?? widget.categories.firstOrNull?.id;
    _limitController = TextEditingController(
      text: widget.existing == null
          ? ''
          : widget.existing!.limitAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Tambah Anggaran' : 'Edit Anggaran',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: widget.categories
                    .map(
                      (category) => DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _categoryId = value),
                validator: (value) => value == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _limitController,
                decoration: const InputDecoration(
                  labelText: 'Batas anggaran',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Masukkan batas anggaran yang valid';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _categoryId == null) {
      return;
    }
    Navigator.pop(
      context,
      Budget(
        id: widget.existing?.id,
        categoryId: _categoryId!,
        month: widget.month.month,
        year: widget.month.year,
        limitAmount: double.parse(_limitController.text),
      ),
    );
  }
}

class _EmptyBudget extends StatelessWidget {
  const _EmptyBudget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Belum ada anggaran. Buat batas per kategori untuk memantau pengeluaran bulanan.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
