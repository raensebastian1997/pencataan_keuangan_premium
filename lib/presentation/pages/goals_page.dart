import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/advisor_cubit.dart';
import '../cubits/cubit_status.dart';
import '../cubits/dashboard_cubit.dart';
import '../cubits/goal_cubit.dart';
import '../widgets/goal_card.dart';
import 'goal_form_page.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GoalCubit, GoalState>(
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
            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openForm(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Goal'),
                ),
              ),
            ),
            if (state.status == CubitStatus.loading)
              const LinearProgressIndicator(),
            Expanded(
              child: state.goals.isEmpty
                  ? const _EmptyGoals()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      itemCount: state.goals.length,
                      itemBuilder: (context, index) {
                        final goal = state.goals[index];
                        return GoalCard(
                          goal: goal,
                          onAddSaving: () => _allocate(context, goal.id),
                          onEdit: () => _openForm(context, goalId: goal.id),
                          onDelete: () => _deleteGoal(context, goal.id),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openForm(BuildContext context, {int? goalId}) async {
    final goalCubit = context.read<GoalCubit>();
    final dashboardCubit = context.read<DashboardCubit>();
    final advisorCubit = context.read<AdvisorCubit>();
    final goal = goalId == null
        ? null
        : goalCubit.state.goals.where((item) => item.id == goalId).firstOrNull;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GoalFormPage(goal: goal)),
    );
    if (!context.mounted) {
      return;
    }
    await dashboardCubit.loadDashboard();
    await advisorCubit.generateAdvice();
  }

  Future<void> _allocate(BuildContext context, int? goalId) async {
    final goalCubit = context.read<GoalCubit>();
    final dashboardCubit = context.read<DashboardCubit>();
    final advisorCubit = context.read<AdvisorCubit>();
    final goal = goalId == null
        ? null
        : goalCubit.state.goals.where((item) => item.id == goalId).firstOrNull;
    if (goal == null) {
      return;
    }
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => const _AllocationDialog(),
    );
    if (amount == null || amount <= 0 || !context.mounted) {
      return;
    }
    await goalCubit.allocateToGoal(goal, amount);
    if (!context.mounted) {
      return;
    }
    await dashboardCubit.loadDashboard();
    await advisorCubit.generateAdvice();
  }

  Future<void> _deleteGoal(BuildContext context, int? id) async {
    if (id == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus goal?'),
        content: const Text('Goal dan progres manualnya akan dihapus.'),
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
    final goalCubit = context.read<GoalCubit>();
    final dashboardCubit = context.read<DashboardCubit>();
    final advisorCubit = context.read<AdvisorCubit>();
    await goalCubit.deleteGoal(id);
    if (!context.mounted) {
      return;
    }
    await dashboardCubit.loadDashboard();
    await advisorCubit.generateAdvice();
  }
}

class _AllocationDialog extends StatefulWidget {
  const _AllocationDialog();

  @override
  State<_AllocationDialog> createState() => _AllocationDialogState();
}

class _AllocationDialogState extends State<_AllocationDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Alokasi'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Jumlah',
            prefixText: 'Rp ',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            final amount = double.tryParse(value ?? '');
            if (amount == null || amount <= 0) {
              return 'Masukkan jumlah yang valid';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, double.parse(_controller.text));
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Belum ada tujuan keuangan. Buat target seperti dana liburan, darurat, atau investasi.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
