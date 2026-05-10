import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/color_utils.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_type.dart';
import '../cubits/advisor_cubit.dart';
import '../cubits/budget_cubit.dart';
import '../cubits/dashboard_cubit.dart';
import '../cubits/transaction_cubit.dart';

class TransactionFormPage extends StatefulWidget {
  const TransactionFormPage({
    super.key,
    this.transaction,
    this.startWithOcr = false,
  });

  final FinancialTransaction? transaction;
  final bool startWithOcr;

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  final ImagePicker _imagePicker = ImagePicker();
  late TransactionType _type;
  late DateTime _date;
  int? _categoryId;
  bool _isScanningAmount = false;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    _amountController = TextEditingController(
      text: transaction == null ? '' : transaction.amount.toStringAsFixed(0),
    );
    _noteController = TextEditingController(text: transaction?.note ?? '');
    _type = transaction?.type ?? TransactionType.expense;
    _date = transaction?.date ?? DateTime.now();
    _categoryId = transaction?.categoryId;
    if (widget.startWithOcr) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scanAmountFromImage();
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.transaction != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Transaksi' : 'Tambah Transaksi'),
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          final categories = state.categories
              .where((category) => category.type == _type)
              .toList();
          if (categories.isNotEmpty &&
              (_categoryId == null ||
                  !categories.any((category) => category.id == _categoryId))) {
            _categoryId = categories.first.id;
          }
          final hasCategories = categories.isNotEmpty;
          final amountValue = double.tryParse(_amountController.text) ?? 0;

          return Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _TypeToggleSection(
                        selectedType: _type,
                        onTypeSelected: (value) {
                          setState(() {
                            _type = value;
                            final filtered = state.categories
                                .where((category) => category.type == _type)
                                .toList();
                            _categoryId = filtered.isEmpty
                                ? null
                                : filtered.first.id;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _type == TransactionType.income
                                ? const [
                                    Color(0xFF23B26B),
                                    Color(0xFF3ECF8E),
                                    Color(0xFF8FE8B7),
                                  ]
                                : const [
                                    Color(0xFF299DDB),
                                    Color(0xFF57B4E2),
                                    Color(0xFF86D0EE),
                                  ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.09),
                              blurRadius: 26,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _type == TransactionType.income
                                  ? 'Nominal pemasukan'
                                  : 'Nominal pengeluaran',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Rp',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.94),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _amountController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: '0',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.75,
                                        ),
                                        fontSize: 34,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      filled: false,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    validator: (value) {
                                      final amount = double.tryParse(
                                        value ?? '',
                                      );
                                      if (amount == null || amount <= 0) {
                                        return 'Masukkan jumlah yang valid';
                                      }
                                      return null;
                                    },
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Tooltip(
                                  message: 'Scan atau upload struk',
                                  child: IconButton(
                                    onPressed: _isScanningAmount
                                        ? null
                                        : _scanAmountFromImage,
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: _isScanningAmount
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.document_scanner_rounded,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              amountValue <= 0
                                  ? 'Masukkan nominal transaksi'
                                  : CurrencyFormatter.format(amountValue),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionTitle(
                        title: 'Kategori',
                        icon: Icons.category_rounded,
                      ),
                      const SizedBox(height: 10),
                      if (hasCategories)
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: categories
                              .map(
                                (category) => _CategoryChip(
                                  category: category,
                                  selected: category.id == _categoryId,
                                  onTap: () {
                                    setState(() => _categoryId = category.id);
                                  },
                                ),
                              )
                              .toList(),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Belum ada kategori untuk tipe transaksi ini. Tambahkan kategori terlebih dahulu di Pengaturan.',
                          ),
                        ),
                      const SizedBox(height: 18),
                      _SectionTitle(
                        title: 'Tanggal Transaksi',
                        icon: Icons.calendar_month_rounded,
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.event_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Tanggal dipilih',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6D7684),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      AppDateUtils.dayMonthYear(_date),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionTitle(
                        title: 'Catatan',
                        icon: Icons.edit_note_rounded,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _noteController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'Tambahkan catatan transaksi (opsional)',
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton.icon(
                    onPressed: hasCategories ? _save : null,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      isEdit ? 'Perbarui Transaksi' : 'Simpan Transaksi',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 5),
      initialDate: _date,
    );
    if (!mounted) {
      return;
    }
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _scanAmountFromImage() async {
    if (!_isMobileOcrSupported) {
      _showMessage('OCR nominal hanya tersedia di Android dan iOS.');
      return;
    }
    if (_isScanningAmount) {
      return;
    }

    final source = await _showOcrSourceSheet();
    if (!mounted || source == null) {
      return;
    }

    setState(() => _isScanningAmount = true);
    TextRecognizer? recognizer;
    final sourceLabel = source == ImageSource.camera ? 'foto kamera' : 'galeri';

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 92,
      );
      if (!mounted || image == null) {
        return;
      }

      recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await recognizer.processImage(inputImage);
      final amount = _extractBestAmount(recognizedText.text);

      if (!mounted) {
        return;
      }

      if (amount == null) {
        final manualAmount = await _showScannedAmountSheet(
          recognizedText: recognizedText.text,
          message:
              'Nominal belum terbaca otomatis dari $sourceLabel. '
              'Cek hasil scan atau isi nominal manual.',
        );
        if (!mounted || manualAmount == null) {
          return;
        }
        _setAmount(manualAmount);
        return;
      }

      _setAmount(amount);
      _showMessage(
        'Nominal ${CurrencyFormatter.format(amount)} berhasil dibaca.',
      );
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      if (_isCameraPermissionError(error.code)) {
        _showMessage(
          'Izin kamera belum aktif. Aktifkan izin kamera untuk NoteUang Me.',
        );
        return;
      }
      if (_isPhotoPermissionError(error.code)) {
        _showMessage(
          'Izin galeri belum aktif. Aktifkan akses foto untuk NoteUang Me.',
        );
        return;
      }
      if (_isPluginRegistrationError(error.code)) {
        _showMessage(
          'Fitur scan perlu rebuild aplikasi setelah dependency baru.',
        );
        return;
      }
      final message = error.message?.trim();
      _showMessage(
        message == null || message.isEmpty
            ? 'Gagal membuka gambar (${error.code}).'
            : 'Gagal membuka gambar: $message',
      );
    } on MissingPluginException {
      if (mounted) {
        _showMessage(
          'Fitur scan perlu rebuild aplikasi setelah dependency baru.',
        );
      }
    } catch (error) {
      if (mounted) {
        debugPrint('Scan nominal gagal: $error');
        final manualAmount = await _showScannedAmountSheet(
          recognizedText: '',
          message:
              'OCR gagal membaca foto. Isi nominal manual untuk melanjutkan.',
        );
        if (!mounted || manualAmount == null) {
          return;
        }
        _setAmount(manualAmount);
      }
    } finally {
      await recognizer?.close();
      if (mounted) {
        setState(() => _isScanningAmount = false);
      }
    }
  }

  bool get _isMobileOcrSupported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<ImageSource?> _showOcrSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.document_scanner_rounded,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Scan Nominal',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Ambil foto struk baru atau pilih gambar dari galeri.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                _OcrSourceTile(
                  icon: Icons.photo_camera_rounded,
                  title: 'Ambil Foto',
                  subtitle: 'Buka kamera dan scan struk langsung',
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 10),
                _OcrSourceTile(
                  icon: Icons.photo_library_rounded,
                  title: 'Upload dari Galeri',
                  subtitle: 'Pilih foto struk yang sudah tersimpan',
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isCameraPermissionError(String code) {
    return code == 'camera_access_denied' ||
        code == 'camera_access_restricted' ||
        code == 'camera_access_denied_without_prompt';
  }

  bool _isPhotoPermissionError(String code) {
    return code == 'photo_access_denied' ||
        code == 'photo_access_restricted' ||
        code == 'photo_access_denied_without_prompt';
  }

  bool _isPluginRegistrationError(String code) {
    return code == 'channel-error' || code == 'missing_plugin';
  }

  void _setAmount(double amount) {
    final value = amount.toStringAsFixed(0);
    _amountController
      ..text = value
      ..selection = TextSelection.collapsed(offset: value.length);
    setState(() {});
  }

  double? _extractBestAmount(String text) {
    final pattern = RegExp(
      r'(?:(rp|idr|total|jumlah|bayar|tagihan|amount|subtotal)\s*[:=]?\s*)?((?:\d{1,3}(?:[.,\s]\d{3})+|\d+)(?:[.,]\d{2})?)',
      caseSensitive: false,
    );
    _AmountCandidate? best;

    for (final rawLine in text.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }
      final lowerLine = line.toLowerCase();
      final amountLine = _normalizeOcrAmountLine(line);
      final hasTotalKeyword = RegExp(
        r'\b(total|grand|jumlah|bayar|tagihan|amount|subtotal)\b',
        caseSensitive: false,
      ).hasMatch(lowerLine);
      final hasNoiseKeyword = RegExp(
        r'\b(tanggal|date|time|jam|telp|telepon|phone|no\.?|nota|invoice|struk|kasir|cashier)\b',
        caseSensitive: false,
      ).hasMatch(lowerLine);

      for (final match in pattern.allMatches(amountLine)) {
        final prefix = (match.group(1) ?? '').toLowerCase();
        final hasCurrencyPrefix = prefix == 'rp' || prefix == 'idr';
        final hasInlineTotalKeyword = prefix.isNotEmpty && !hasCurrencyPrefix;
        final amount = _parseAmount(match.group(2) ?? '');
        if (amount == null || amount < 100) {
          continue;
        }

        final digitsLength = (match.group(2) ?? '')
            .replaceAll(RegExp(r'\D'), '')
            .length;
        if (!hasCurrencyPrefix && !hasTotalKeyword && digitsLength > 9) {
          continue;
        }

        var score = amount;
        if (hasCurrencyPrefix) {
          score *= 3.0;
        }
        if (hasTotalKeyword) {
          score *= 5.0;
        }
        if (hasInlineTotalKeyword) {
          score *= 4.0;
        }
        if (hasNoiseKeyword) {
          score *= 0.12;
        }

        final candidate = _AmountCandidate(amount: amount, score: score);
        if (best == null || candidate.score > best.score) {
          best = candidate;
        }
      }
    }

    return best?.amount;
  }

  String _normalizeOcrAmountLine(String line) {
    final buffer = StringBuffer();
    for (var index = 0; index < line.length; index++) {
      final char = line[index];
      final previous = index == 0 ? '' : line[index - 1];
      final next = index == line.length - 1 ? '' : line[index + 1];
      final nearAmountCharacter =
          _isAmountCharacter(previous) || _isAmountCharacter(next);

      if (nearAmountCharacter && (char == 'O' || char == 'o')) {
        buffer.write('0');
      } else if (nearAmountCharacter &&
          (char == 'l' || char == 'I' || char == '|')) {
        buffer.write('1');
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  bool _isAmountCharacter(String value) {
    if (value.isEmpty) {
      return false;
    }
    final codeUnit = value.codeUnitAt(0);
    return (codeUnit >= 48 && codeUnit <= 57) ||
        value == '.' ||
        value == ',' ||
        value.trim().isEmpty;
  }

  double? _parseAmount(String raw) {
    var normalized = raw.trim().replaceAll(RegExp(r'\s+'), '');
    if (normalized.isEmpty) {
      return null;
    }
    final lastComma = normalized.lastIndexOf(',');
    final lastDot = normalized.lastIndexOf('.');
    final decimalIndex = lastComma > lastDot ? lastComma : lastDot;
    final hasDecimalCents =
        decimalIndex >= 0 && normalized.length - decimalIndex - 1 == 2;

    if (hasDecimalCents) {
      normalized = normalized.substring(0, decimalIndex);
    }

    final digits = normalized.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return null;
    }
    final value = double.tryParse(digits);
    if (value == null || value > 1000000000000) {
      return null;
    }
    return value;
  }

  Future<double?> _showScannedAmountSheet({
    required String recognizedText,
    required String message,
  }) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return _ScannedAmountSheet(
          recognizedText: recognizedText,
          message: message,
          parseAmount: _parseAmount,
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) {
      return;
    }
    final transaction = FinancialTransaction(
      id: widget.transaction?.id,
      amount: double.parse(_amountController.text),
      type: _type,
      categoryId: _categoryId!,
      date: _date,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    final transactionCubit = context.read<TransactionCubit>();
    final dashboardCubit = context.read<DashboardCubit>();
    final advisorCubit = context.read<AdvisorCubit>();
    final budgetCubit = context.read<BudgetCubit>();
    await transactionCubit.saveTransaction(transaction);
    if (!mounted) {
      return;
    }
    await dashboardCubit.loadDashboard();
    await advisorCubit.generateAdvice();
    await budgetCubit.loadMonth(budgetCubit.state.month);
    if (!mounted) {
      return;
    }
    Navigator.pop(context, true);
  }
}

class _AmountCandidate {
  const _AmountCandidate({required this.amount, required this.score});

  final double amount;
  final double score;
}

class _OcrSourceTile extends StatelessWidget {
  const _OcrSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
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

class _ScannedAmountSheet extends StatefulWidget {
  const _ScannedAmountSheet({
    required this.recognizedText,
    required this.message,
    required this.parseAmount,
  });

  final String recognizedText;
  final String message;
  final double? Function(String value) parseAmount;

  @override
  State<_ScannedAmountSheet> createState() => _ScannedAmountSheetState();
}

class _ScannedAmountSheetState extends State<_ScannedAmountSheet> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = widget.parseAmount(_controller.text);
    if (amount == null || amount <= 0) {
      setState(() => _errorText = 'Masukkan nominal yang valid');
      return;
    }
    Navigator.pop(context, amount);
  }

  @override
  Widget build(BuildContext context) {
    final recognizedText = widget.recognizedText.trim();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.document_scanner_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Konfirmasi Nominal',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(widget.message),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Nominal',
              prefixText: 'Rp ',
              errorText: _errorText,
            ),
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
          ),
          if (recognizedText.isNotEmpty) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Teks yang terbaca',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    recognizedText,
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Gunakan Nominal'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeToggleSection extends StatelessWidget {
  const _TypeToggleSection({
    required this.selectedType,
    required this.onTypeSelected,
  });

  final TransactionType selectedType;
  final ValueChanged<TransactionType> onTypeSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TypeToggleButton(
              label: 'Pengeluaran',
              icon: Icons.north_east_rounded,
              selected: selectedType == TransactionType.expense,
              selectedColor: const Color(0xFF299DDB),
              onTap: () => onTypeSelected(TransactionType.expense),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _TypeToggleButton(
              label: 'Pemasukan',
              icon: Icons.south_west_rounded,
              selected: selectedType == TransactionType.income,
              selectedColor: const Color(0xFF22B56C),
              onTap: () => onTypeSelected(TransactionType.income),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeToggleButton extends StatelessWidget {
  const _TypeToggleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? Colors.white : const Color(0xFF5D6775);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? selectedColor : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFF5F6B7A)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final FinanceCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.fromHex(category.colorHex);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.17) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.85)
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
