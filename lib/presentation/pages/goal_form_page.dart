import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/goal.dart';
import '../cubits/goal_cubit.dart';

class GoalFormPage extends StatefulWidget {
  const GoalFormPage({super.key, this.goal});

  final FinancialGoal? goal;

  @override
  State<GoalFormPage> createState() => _GoalFormPageState();
}

class _GoalFormPageState extends State<GoalFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  late final TextEditingController _savedController;
  late DateTime _targetDate;

  bool get _isEditing => widget.goal != null;

  double get _targetAmount => double.tryParse(_targetController.text) ?? 0;

  double get _savedAmount => double.tryParse(_savedController.text) ?? 0;

  double get _remainingAmount =>
      (_targetAmount - _savedAmount).clamp(0, double.infinity).toDouble();

  int get _monthsRemaining => AppDateUtils.monthsUntil(_targetDate);

  double get _suggestedMonthlySaving {
    if (_remainingAmount <= 0) {
      return 0;
    }
    return _remainingAmount / _monthsRemaining;
  }

  double get _progress {
    if (_targetAmount <= 0) {
      return 0;
    }
    return (_savedAmount / _targetAmount).clamp(0, 1).toDouble();
  }

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _nameController = TextEditingController(text: goal?.name ?? '');
    _targetController = TextEditingController(
      text: goal == null ? '' : goal.targetAmount.toStringAsFixed(0),
    );
    _savedController = TextEditingController(
      text: goal == null ? '0' : goal.savedAmount.toStringAsFixed(0),
    );
    _targetDate =
        goal?.targetDate ??
        DateTime(
          DateTime.now().year,
          DateTime.now().month + 12,
          DateTime.now().day,
        );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(_isEditing ? 'Edit Goal' : 'Goal Baru'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _GoalHeroPreview(
                    title: _nameController.text.trim().isEmpty
                        ? 'Rencana Masa Depan'
                        : _nameController.text.trim(),
                    targetAmount: _targetAmount,
                    savedAmount: _savedAmount,
                    remainingAmount: _remainingAmount,
                    progress: _progress,
                    targetDate: _targetDate,
                    suggestedMonthlySaving: _suggestedMonthlySaving,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          icon: Icons.flag_rounded,
                          title: 'Detail Goal',
                          subtitle: 'Buat target yang spesifik dan realistis.',
                        ),
                        const SizedBox(height: 12),
                        _PremiumPanel(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(
                                context,
                                label: 'Nama goal',
                                hint: 'Dana liburan, rumah, darurat',
                                icon: Icons.auto_awesome_rounded,
                              ),
                              validator: (value) => (value ?? '').trim().isEmpty
                                  ? 'Nama goal wajib diisi'
                                  : null,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _targetController,
                              decoration: _inputDecoration(
                                context,
                                label: 'Target jumlah',
                                hint: '10000000',
                                icon: Icons.savings_rounded,
                                prefixText: 'Rp ',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                final amount = double.tryParse(value ?? '');
                                if (amount == null || amount <= 0) {
                                  return 'Masukkan target yang valid';
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _savedController,
                              decoration: _inputDecoration(
                                context,
                                label: 'Jumlah terkumpul',
                                hint: '0',
                                icon: Icons.account_balance_wallet_rounded,
                                prefixText: 'Rp ',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                final amount = double.tryParse(value ?? '');
                                if (amount == null || amount < 0) {
                                  return 'Masukkan jumlah yang valid';
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _SectionHeader(
                          icon: Icons.event_available_rounded,
                          title: 'Timeline',
                          subtitle: 'Pilih tanggal target pencapaian.',
                        ),
                        const SizedBox(height: 12),
                        _DateTargetCard(
                          targetDate: _targetDate,
                          monthsRemaining: _monthsRemaining,
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 20),
                        _SectionHeader(
                          icon: Icons.insights_rounded,
                          title: 'Rencana Setoran',
                          subtitle: 'Estimasi otomatis berdasarkan targetmu.',
                        ),
                        const SizedBox(height: 12),
                        _SavingPlanCard(
                          remainingAmount: _remainingAmount,
                          monthsRemaining: _monthsRemaining,
                          suggestedMonthlySaving: _suggestedMonthlySaving,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _BottomSubmitBar(
              label: _isEditing ? 'Perbarui Goal' : 'Simpan Goal',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
    String? prefixText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(now.year + 20, 12, 31);
    final picked = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: _targetDate.isBefore(firstDate) ? firstDate : _targetDate,
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final goal = FinancialGoal(
      id: widget.goal?.id,
      name: _nameController.text.trim(),
      targetAmount: double.parse(_targetController.text),
      targetDate: _targetDate,
      savedAmount: double.parse(_savedController.text),
    );
    await context.read<GoalCubit>().saveGoal(goal);
    if (!mounted) {
      return;
    }
    Navigator.pop(context, true);
  }
}

class _GoalHeroPreview extends StatelessWidget {
  const _GoalHeroPreview({
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    required this.remainingAmount,
    required this.progress,
    required this.targetDate,
    required this.suggestedMonthlySaving,
  });

  final String title;
  final double targetAmount;
  final double savedAmount;
  final double remainingAmount;
  final double progress;
  final DateTime targetDate;
  final double suggestedMonthlySaving;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? colorScheme.onSurface : Colors.white;
    final mutedForeground = foreground.withValues(alpha: 0.76);

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + kToolbarHeight + 14,
        16,
        22,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF121A22),
                  Color(0xFF143C4C),
                  Color(0xFF166B73),
                ]
              : const [
                  Color(0xFF1FA7D8),
                  Color(0xFF36B7D7),
                  Color(0xFF63D6C7),
                ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.14 : 0.2),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Goal Finansial',
                      style: TextStyle(
                        color: mutedForeground,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        title,
                        key: ValueKey(title),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 28,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Target ${AppDateUtils.dayMonthYear(targetDate)}',
                      style: TextStyle(
                        color: mutedForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              _ProgressBadge(progress: progress, foreground: foreground),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.18),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.26),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      CurrencyFormatter.format(targetAmount),
                      style: TextStyle(
                        color: foreground,
                        fontSize: 30,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    valueColor: AlwaysStoppedAnimation<Color>(foreground),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _HeroMetric(
                        label: 'Terkumpul',
                        value: CurrencyFormatter.format(savedAmount),
                        foreground: foreground,
                        mutedForeground: mutedForeground,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HeroMetric(
                        label: 'Sisa',
                        value: CurrencyFormatter.format(remainingAmount),
                        foreground: foreground,
                        mutedForeground: mutedForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_view_month_rounded,
                      size: 18,
                      color: mutedForeground,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Saran setoran '
                        '${CurrencyFormatter.format(suggestedMonthlySaving)} '
                        'per bulan',
                        style: TextStyle(
                          color: mutedForeground,
                          fontWeight: FontWeight.w700,
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

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.progress, required this.foreground});

  final double progress;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              backgroundColor: foreground.withValues(alpha: 0.22),
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          ),
          Text(
            '${(progress * 100).round()}%',
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w900,
              fontSize: 18,
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
    required this.foreground,
    required this.mutedForeground,
  });

  final String label;
  final String value;
  final Color foreground;
  final Color mutedForeground;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: mutedForeground,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
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

class _PremiumPanel extends StatelessWidget {
  const _PremiumPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _DateTargetCard extends StatelessWidget {
  const _DateTargetCard({
    required this.targetDate,
    required this.monthsRemaining,
    required this.onTap,
  });

  final DateTime targetDate;
  final int monthsRemaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDateUtils.dayMonthYear(targetDate),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$monthsRemaining bulan tersisa',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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

class _SavingPlanCard extends StatelessWidget {
  const _SavingPlanCard({
    required this.remainingAmount,
    required this.monthsRemaining,
    required this.suggestedMonthlySaving,
  });

  final double remainingAmount;
  final int monthsRemaining;
  final double suggestedMonthlySaving;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.payments_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyFormatter.format(suggestedMonthlySaving),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Setoran ideal per bulan',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PlanChip(
                label: 'Sisa Target',
                value: CurrencyFormatter.format(remainingAmount),
              ),
              _PlanChip(
                label: 'Durasi',
                value: '$monthsRemaining bulan',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _BottomSubmitBar extends StatelessWidget {
  const _BottomSubmitBar({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.94),
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: Text(label),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}
