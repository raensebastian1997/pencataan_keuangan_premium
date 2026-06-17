import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/advisor_cubit.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/settings_cubit.dart';
import 'category_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _openAiConfigSheet(
    BuildContext rootContext,
    SettingsState currentState,
  ) async {
    await showModalBottomSheet<void>(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: Theme.of(rootContext).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _AiConfigSheet(initialState: currentState),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 20),
      children: [
        const SizedBox(height: 100),

        BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return Card(
              child: SwitchListTile(
                value: state.isDarkMode,
                onChanged: (value) =>
                    context.read<SettingsCubit>().setDarkMode(value),
                secondary: const Icon(Icons.dark_mode),
                title: const Text('Dark mode'),
                subtitle: const Text('Simpan preferensi tema di perangkat'),
              ),
            );
          },
        ),
        BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return Card(
              child: Column(
                children: [
                  SwitchListTile(
                    value: state.aiEnabled,
                    onChanged: state.hasAiApiKey
                        ? (value) async {
                            await context.read<SettingsCubit>().setAiEnabled(
                              value,
                            );
                            await context.read<AdvisorCubit>().generateAdvice();
                          }
                        : null,
                    secondary: const Icon(Icons.smart_toy_outlined),
                    title: const Text('Analisis AI'),
                    subtitle: Text(
                      state.hasAiApiKey
                          ? 'Aktifkan analisis AI untuk saran lebih adaptif'
                          : 'Tambahkan API key terlebih dahulu',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.tune_rounded),
                    title: const Text('Konfigurasi AI'),
                    subtitle: Text(
                      state.hasAiApiKey
                          ? 'Model: ${state.aiModel}'
                          : 'Belum ada API key tersimpan',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openAiConfigSheet(context, state),
                  ),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Kelola Kategori'),
              subtitle: const Text(
                'Tambah, edit, atau hapus kategori transaksi',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoryPage()),
              ),
            ),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.verified_user_outlined),
            title: Text('Financial Tracker & Future Advisor'),
            subtitle: Text(
              'Data tersimpan lokal perangkat. API key AI disimpan lokal di perangkat ini.',
            ),
          ),
        ),
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final user = authState.user;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: Text(user?.fullName ?? 'Pengguna Lokal'),
                  subtitle: Text(user?.email ?? 'Belum login'),
                ),
              ),
            );
          },
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            subtitle: const Text('Keluar dari sesi saat ini'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.read<AuthCubit>().logout(),
          ),
        ),
      ],
    );
  }
}

class _AiConfigSheet extends StatefulWidget {
  const _AiConfigSheet({required this.initialState});

  final SettingsState initialState;

  @override
  State<_AiConfigSheet> createState() => _AiConfigSheetState();
}

class _AiConfigSheetState extends State<_AiConfigSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _apiKeyController;
  late final TextEditingController _modelController;
  late bool _isEnabled;
  bool _obscureKey = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _modelController = TextEditingController(text: widget.initialState.aiModel);
    _isEnabled = widget.initialState.aiEnabled;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_isSubmitting) {
      return;
    }

    final settingsCubit = context.read<SettingsCubit>();
    final advisorCubit = context.read<AdvisorCubit>();
    final apiKey = _apiKeyController.text.trim();
    final model = _modelController.text.trim();

    setState(() => _isSubmitting = true);
    await settingsCubit.saveAiConfiguration(
      apiKey: apiKey.isEmpty ? null : apiKey,
      model: model,
      enabled: _isEnabled,
    );
    await advisorCubit.generateAdvice();

    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _deleteApiKey() async {
    if (_isSubmitting) {
      return;
    }

    final settingsCubit = context.read<SettingsCubit>();
    final advisorCubit = context.read<AdvisorCubit>();
    final model = _modelController.text.trim();

    setState(() => _isSubmitting = true);
    await settingsCubit.saveAiConfiguration(
      apiKey: '',
      model: model,
      enabled: false,
    );
    await advisorCubit.generateAdvice();

    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Konfigurasi Analisis AI',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Masukkan API key untuk mengaktifkan analisa keuangan berbasis AI.',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _apiKeyController,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-...',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureKey
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscureKey = !_obscureKey);
                  },
                ),
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                if (widget.initialState.hasAiApiKey && text.isEmpty) {
                  return null;
                }
                if (text.isEmpty) {
                  return 'API key wajib diisi untuk aktivasi AI';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Model AI',
                hintText: 'gpt-4o-mini',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Model tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktifkan analisis AI'),
              subtitle: const Text(
                'Saat aktif, saran akan dibuat model AI berbasis data transaksi',
              ),
              value: _isEnabled,
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      setState(() => _isEnabled = value);
                    },
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _save,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Simpan Konfigurasi AI'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            if (widget.initialState.hasAiApiKey) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: _isSubmitting ? null : _deleteApiKey,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Hapus API Key dari Perangkat'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
