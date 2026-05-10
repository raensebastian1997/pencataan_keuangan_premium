import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/utils/currency_formatter.dart';

void main() {
  test('format rupiah tanpa desimal', () {
    expect(CurrencyFormatter.format(1500000), contains('1.500.000'));
  });
}
