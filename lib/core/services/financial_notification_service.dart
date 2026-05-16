import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/repositories/auth_repository.dart';
import '../navigation/app_navigator.dart';
import '../utils/currency_formatter.dart';

class FinancialNotificationHistoryItem {
  const FinancialNotificationHistoryItem({
    required this.title,
    required this.body,
    required this.createdAt,
    required this.payload,
  });

  final String title;
  final String body;
  final DateTime createdAt;
  final String payload;

  factory FinancialNotificationHistoryItem.fromJson(Map<String, Object?> json) {
    return FinancialNotificationHistoryItem(
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      payload: json['payload'] as String? ?? '',
    );
  }

  Map<String, Object?> toJson() {
    return {
      'title': title,
      'body': body,
      'created_at': createdAt.toIso8601String(),
      'payload': payload,
    };
  }
}

class FinancialNotificationService {
  FinancialNotificationService(
    this._prefs,
    this._notifications,
    this._authRepository,
  );

  static const _negativeBalanceNotificationId = 1001;
  static const _lastNegativeBalanceAlertDateKey =
      'last_negative_balance_alert_date';
  static const _negativeBalanceChannelId = 'financial_health_alerts';
  static const _negativeBalanceChannelName = 'Financial Health Alerts';
  static const _activityChannelId = 'finance_activity';
  static const _activityChannelName = 'Finance Activity';
  static const _notificationHistoryKey = 'notification_history';

  final SharedPreferences _prefs;
  final FlutterLocalNotificationsPlugin _notifications;
  final AuthRepository _authRepository;

  Future<void> initialize() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (_) {
        openAppFromNotification();
      },
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> notifyIfBalanceIsNegative(double balance) async {
    if (balance >= 0) {
      await _prefs.remove(_lastNegativeBalanceAlertDateKey);
      return;
    }

    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (_prefs.getString(_lastNegativeBalanceAlertDateKey) == todayKey) {
      return;
    }

    await _notifications.show(
      id: _negativeBalanceNotificationId,
      title: _negativeBalanceTitle,
      body: _negativeBalanceBody(balance),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _negativeBalanceChannelId,
          _negativeBalanceChannelName,
          channelDescription:
              'Peringatan saat kondisi keuangan perlu perhatian.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      payload: 'negative_balance',
    );
    await _saveHistory(
      title: _negativeBalanceTitle,
      body: _negativeBalanceBody(balance),
      payload: 'negative_balance',
    );

    await _prefs.setString(_lastNegativeBalanceAlertDateKey, todayKey);
    await _openWhatsappReport(balance);
  }

  Future<void> showInputSavedNotification({
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _activityChannelId,
          _activityChannelName,
          channelDescription:
              'Notifikasi saat data keuangan berhasil disimpan.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      payload: 'input_saved',
    );
    await _saveHistory(title: title, body: body, payload: 'input_saved');
  }

  Future<List<FinancialNotificationHistoryItem>>
  getNotificationHistory() async {
    final rawItems = _prefs.getStringList(_notificationHistoryKey) ?? const [];
    return rawItems
        .map((item) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map<String, Object?>) {
              return FinancialNotificationHistoryItem.fromJson(decoded);
            }
          } catch (_) {}
          return null;
        })
        .whereType<FinancialNotificationHistoryItem>()
        .toList();
  }

  Future<void> _saveHistory({
    required String title,
    required String body,
    required String payload,
  }) async {
    final history = await getNotificationHistory();
    final nextHistory = [
      FinancialNotificationHistoryItem(
        title: title,
        body: body,
        payload: payload,
        createdAt: DateTime.now(),
      ),
      ...history,
    ].take(50).map((item) => jsonEncode(item.toJson())).toList();

    await _prefs.setStringList(_notificationHistoryKey, nextHistory);
  }

  Future<void> _openWhatsappReport(double balance) async {
    final user = await _authRepository.getSessionUser();
    final whatsappNumber = user?.whatsappNumber.trim() ?? '';
    if (whatsappNumber.isEmpty) {
      return;
    }

    final message = _buildFinancialReport(balance);
    final uri = Uri.https('wa.me', '/$whatsappNumber', {'text': message});
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _buildFinancialReport(double balance) {
    final formattedBalance = CurrencyFormatter.format(balance);
    return '''
Laporan Keuangan NoteUang Me

Status: Keuangan sedang tidak sehat
Total balance: $formattedBalance

Saran:
1. Tahan dulu pengeluaran non-prioritas sampai balance kembali positif.
2. Cek kategori pengeluaran terbesar bulan ini dan batasi nilainya.
3. Prioritaskan pembayaran kebutuhan wajib, lalu sisihkan pemasukan berikutnya untuk menutup minus.
4. Buat target harian agar pengeluaran tidak melebihi pemasukan.
''';
  }

  String get _negativeBalanceTitle => 'Keuangan sedang tidak sehat';

  String _negativeBalanceBody(double balance) {
    return 'Total balance kamu ${CurrencyFormatter.format(balance)}. Cek pengeluaran dan pemasukan bulan ini.';
  }
}
