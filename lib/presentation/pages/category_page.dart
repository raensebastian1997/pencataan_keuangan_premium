import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/color_utils.dart';
import '../../core/utils/material_icon_resolver.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/transaction_type.dart';
import '../cubits/category_cubit.dart';
import '../cubits/cubit_status.dart';
import '../cubits/transaction_cubit.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Kategori')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Kategori'),
      ),
      body: BlocConsumer<CategoryCubit, CategoryState>(
        listener: (context, state) {
          if (state.status == CubitStatus.failure && state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          final income = state.categories
              .where((item) => item.type == TransactionType.income)
              .toList();
          final expense = state.categories
              .where((item) => item.type == TransactionType.expense)
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              if (state.status == CubitStatus.loading)
                const LinearProgressIndicator(),
              _CategorySection(
                title: 'Pengeluaran',
                categories: expense,
                onEdit: (category) => _openForm(context, category: category),
                onDelete: (category) => _confirmDelete(context, category),
              ),
              const SizedBox(height: 20),
              _CategorySection(
                title: 'Pemasukan',
                categories: income,
                onEdit: (category) => _openForm(context, category: category),
                onDelete: (category) => _confirmDelete(context, category),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context, {
    FinanceCategory? category,
  }) async {
    final result = await showDialog<FinanceCategory>(
      context: context,
      builder: (context) => _CategoryFormDialog(existing: category),
    );
    if (result == null || !context.mounted) {
      return;
    }
    await context.read<CategoryCubit>().saveCategory(result);
    if (!context.mounted) {
      return;
    }
    await context.read<TransactionCubit>().loadTransactions();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    FinanceCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus ${category.name}?'),
        content: const Text(
          'Kategori yang sudah dipakai transaksi atau anggaran akan diblokir dari penghapusan.',
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
    if (confirmed != true || category.id == null || !context.mounted) {
      return;
    }
    await context.read<CategoryCubit>().deleteCategory(category.id!);
    if (!context.mounted) {
      return;
    }
    await context.read<TransactionCubit>().loadTransactions();
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.categories,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final List<FinanceCategory> categories;
  final ValueChanged<FinanceCategory> onEdit;
  final ValueChanged<FinanceCategory> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (categories.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Belum ada kategori.'),
            ),
          )
        else
          ...categories.map((category) {
            final color = ColorUtils.fromHex(category.colorHex);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.16),
                    foregroundColor: color,
                    child: Icon(
                      MaterialIconResolver.fromCodePoint(
                        category.iconCodePoint,
                      ),
                    ),
                  ),
                  title: Text(
                    category.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(category.type.label),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) =>
                        value == 'edit' ? onEdit(category) : onDelete(category),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({this.existing});

  final FinanceCategory? existing;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late TransactionType _type;
  late int _iconCodePoint;
  late String _colorHex;

  static const _icons = [
    _IconOption('Makanan', Icons.restaurant),
    _IconOption('Mobil', Icons.directions_car),
    _IconOption('Belanja', Icons.shopping_bag),
    _IconOption('Tagihan', Icons.receipt_long),
    _IconOption('Kerja', Icons.work),
    _IconOption('Gaji', Icons.payments),
    _IconOption('Tabungan', Icons.savings),
    _IconOption('Investasi', Icons.trending_up),
  ];

  static const _colors = [
    '#00A884',
    '#22C55E',
    '#06B6D4',
    '#3B82F6',
    '#8B5CF6',
    '#EC4899',
    '#F97316',
    '#EF4444',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _type = existing?.type ?? TransactionType.expense;
    _iconCodePoint = existing?.iconCodePoint ?? Icons.category.codePoint;
    _colorHex = existing?.colorHex ?? _colors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Tambah Kategori' : 'Edit Kategori',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama kategori'),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Nama kategori wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TransactionType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipe'),
                items: TransactionType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue:
                    _icons.any((item) => item.icon.codePoint == _iconCodePoint)
                    ? _iconCodePoint
                    : Icons.category.codePoint,
                decoration: const InputDecoration(labelText: 'Ikon'),
                items: [
                  DropdownMenuItem(
                    value: Icons.category.codePoint,
                    child: const Row(
                      children: [
                        Icon(Icons.category),
                        SizedBox(width: 8),
                        Text('Kategori'),
                      ],
                    ),
                  ),
                  ..._icons.map(
                    (option) => DropdownMenuItem(
                      value: option.icon.codePoint,
                      child: Row(
                        children: [
                          Icon(option.icon),
                          SizedBox(width: 8),
                          Text(option.label),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _iconCodePoint = value ?? _iconCodePoint),
              ),
              const SizedBox(height: 16),
              Text('Warna', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colors.map((hex) {
                  final color = ColorUtils.fromHex(hex);
                  final selected = _colorHex == hex;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => _colorHex = hex),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  );
                }).toList(),
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
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.pop(
      context,
      FinanceCategory(
        id: widget.existing?.id,
        name: _nameController.text.trim(),
        type: _type,
        iconCodePoint: _iconCodePoint,
        colorHex: _colorHex,
      ),
    );
  }
}

class _IconOption {
  const _IconOption(this.label, this.icon);

  final String label;
  final IconData icon;
}
