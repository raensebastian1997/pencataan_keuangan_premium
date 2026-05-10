import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

class CurrencyFormatter {
  const CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: AppConstants.localeId,
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 0,
  );

  static String format(num value) => _formatter.format(value);
}
