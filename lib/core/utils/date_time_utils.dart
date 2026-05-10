import 'package:intl/intl.dart';

class AppDateUtils {
  const AppDateUtils._();

  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month);

  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  static DateTime startOfPreviousMonth(DateTime date) {
    return DateTime(date.year, date.month - 1);
  }

  static DateTime endOfPreviousMonth(DateTime date) {
    return DateTime(date.year, date.month, 0, 23, 59, 59, 999);
  }

  static String monthYear(DateTime date) =>
      DateFormat('MMMM yyyy', 'id_ID').format(date);

  static String dayMonthYear(DateTime date) =>
      DateFormat('dd MMM yyyy', 'id_ID').format(date);

  static int monthsUntil(DateTime target) {
    final now = DateTime.now();
    final raw = (target.year - now.year) * 12 + target.month - now.month;
    return raw <= 0 ? 1 : raw;
  }
}
