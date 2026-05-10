enum TransactionType { income, expense }

extension TransactionTypeX on TransactionType {
  String get value => this == TransactionType.income ? 'income' : 'expense';

  String get label =>
      this == TransactionType.income ? 'Pemasukan' : 'Pengeluaran';
}

TransactionType transactionTypeFromString(String value) {
  return value == TransactionType.income.value
      ? TransactionType.income
      : TransactionType.expense;
}
