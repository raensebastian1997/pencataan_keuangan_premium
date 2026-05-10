import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/transaction_type.dart';

class LocalDatabase {
  static const _databaseName = 'money_tracker.db';
  static const _databaseVersion = 2;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(directory.path, _databaseName);
    return openDatabase(
      dbPath,
      version: _databaseVersion,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_code_point INTEGER NOT NULL,
        color_hex TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT
      )
    ''');
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        limit_amount REAL NOT NULL,
        UNIQUE(category_id, month, year),
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT
      )
    ''');
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        target_date TEXT NOT NULL,
        saved_amount REAL NOT NULL DEFAULT 0
      )
    ''');
    await _createUsersTable(db);
    await _seedCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createUsersTable(db);
    }
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL,
        email_lower TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _seedCategories(Database db) async {
    final categories = [
      _seed(
        'Makanan',
        TransactionType.expense,
        Icons.restaurant.codePoint,
        '#F97316',
      ),
      _seed(
        'Transportasi',
        TransactionType.expense,
        Icons.directions_car.codePoint,
        '#06B6D4',
      ),
      _seed(
        'Belanja',
        TransactionType.expense,
        Icons.shopping_bag.codePoint,
        '#EC4899',
      ),
      _seed(
        'Hiburan',
        TransactionType.expense,
        Icons.movie.codePoint,
        '#8B5CF6',
      ),
      _seed(
        'Tagihan',
        TransactionType.expense,
        Icons.receipt_long.codePoint,
        '#EF4444',
      ),
      _seed(
        'Kesehatan',
        TransactionType.expense,
        Icons.health_and_safety.codePoint,
        '#10B981',
      ),
      _seed(
        'Pendidikan',
        TransactionType.expense,
        Icons.school.codePoint,
        '#3B82F6',
      ),
      _seed(
        'Tabungan/Goal',
        TransactionType.expense,
        Icons.savings.codePoint,
        '#14B8A6',
      ),
      _seed(
        'Investasi',
        TransactionType.expense,
        Icons.trending_up.codePoint,
        '#84CC16',
      ),
      _seed(
        'Gaji',
        TransactionType.income,
        Icons.payments.codePoint,
        '#22C55E',
      ),
      _seed(
        'Bonus',
        TransactionType.income,
        Icons.card_giftcard.codePoint,
        '#EAB308',
      ),
      _seed(
        'Freelance',
        TransactionType.income,
        Icons.work.codePoint,
        '#0EA5E9',
      ),
      _seed(
        'Hadiah',
        TransactionType.income,
        Icons.redeem.codePoint,
        '#A855F7',
      ),
    ];
    final batch = db.batch();
    for (final category in categories) {
      batch.insert('categories', category);
    }
    await batch.commit(noResult: true);
  }

  Map<String, Object?> _seed(
    String name,
    TransactionType type,
    int iconCodePoint,
    String colorHex,
  ) {
    return {
      'name': name,
      'type': type.value,
      'icon_code_point': iconCodePoint,
      'color_hex': colorHex,
    };
  }

  Future<List<Map<String, Object?>>> getCategories({String? type}) async {
    final db = await database;
    return db.query(
      'categories',
      where: type == null ? null : 'type = ?',
      whereArgs: type == null ? null : [type],
      orderBy: 'type ASC, name ASC',
    );
  }

  Future<Map<String, Object?>?> getCategoryById(int id) async {
    final db = await database;
    final rows = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> insertCategory(Map<String, Object?> values) async {
    final db = await database;
    return db.insert('categories', values);
  }

  Future<int> updateCategory(int id, Map<String, Object?> values) async {
    final db = await database;
    return db.update('categories', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isCategoryInUse(int id) async {
    final db = await database;
    final transactionCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM transactions WHERE category_id = ?',
            [id],
          ),
        ) ??
        0;
    final budgetCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM budgets WHERE category_id = ?',
            [id],
          ),
        ) ??
        0;
    return transactionCount + budgetCount > 0;
  }

  Future<List<Map<String, Object?>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
  }) async {
    final db = await database;
    final clauses = <String>[];
    final args = <Object?>[];
    if (startDate != null) {
      clauses.add('t.date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      clauses.add('t.date <= ?');
      args.add(endDate.toIso8601String());
    }
    if (categoryId != null) {
      clauses.add('t.category_id = ?');
      args.add(categoryId);
    }
    final where = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    return db.rawQuery('''
      SELECT
        t.*,
        c.name AS category_name,
        c.color_hex AS category_color_hex,
        c.icon_code_point AS category_icon_code_point
      FROM transactions t
      LEFT JOIN categories c ON c.id = t.category_id
      $where
      ORDER BY t.date DESC
    ''', args);
  }

  Future<int> insertTransaction(Map<String, Object?> values) async {
    final db = await database;
    return db.insert('transactions', values);
  }

  Future<int> updateTransaction(int id, Map<String, Object?> values) async {
    final db = await database;
    return db.update('transactions', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotal(
    String type,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE type = ? AND date >= ? AND date <= ?
    ''',
      [type, startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return (rows.first['total'] as num).toDouble();
  }

  Future<double> getCategoryExpense(
    int categoryId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE type = ? AND category_id = ? AND date >= ? AND date <= ?
    ''',
      [
        TransactionType.expense.value,
        categoryId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
    );
    return (rows.first['total'] as num).toDouble();
  }

  Future<List<Map<String, Object?>>> getExpenseByCategory(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT
        c.id AS category_id,
        c.name AS category_name,
        c.color_hex AS category_color_hex,
        SUM(t.amount) AS total
      FROM transactions t
      INNER JOIN categories c ON c.id = t.category_id
      WHERE t.type = ? AND t.date >= ? AND t.date <= ?
      GROUP BY c.id, c.name, c.color_hex
      HAVING total > 0
      ORDER BY total DESC
    ''',
      [
        TransactionType.expense.value,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
    );
  }

  Future<List<Map<String, Object?>>> getMonthlyComparison(
    DateTime startMonth,
  ) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT
        substr(date, 1, 7) AS month_key,
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS expense
      FROM transactions
      WHERE date >= ?
      GROUP BY month_key
      ORDER BY month_key ASC
    ''',
      [startMonth.toIso8601String()],
    );
  }

  Future<List<Map<String, Object?>>> getBudgets(int month, int year) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT
        b.*,
        c.name AS category_name,
        c.color_hex AS category_color_hex,
        c.icon_code_point AS category_icon_code_point
      FROM budgets b
      INNER JOIN categories c ON c.id = b.category_id
      WHERE b.month = ? AND b.year = ?
      ORDER BY c.name ASC
    ''',
      [month, year],
    );
  }

  Future<int> upsertBudget(Map<String, Object?> values) async {
    final db = await database;
    final id = values['id'] as int?;
    if (id != null) {
      await db.update('budgets', values, where: 'id = ?', whereArgs: [id]);
      return id;
    }
    final existing = await db.query(
      'budgets',
      columns: ['id'],
      where: 'category_id = ? AND month = ? AND year = ?',
      whereArgs: [values['category_id'], values['month'], values['year']],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      final existingId = existing.first['id'] as int;
      await db.update(
        'budgets',
        values,
        where: 'id = ?',
        whereArgs: [existingId],
      );
      return existingId;
    }
    return db.insert('budgets', values);
  }

  Future<int> deleteBudget(int id) async {
    final db = await database;
    return db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> getGoals() async {
    final db = await database;
    return db.query('goals', orderBy: 'target_date ASC');
  }

  Future<int> insertGoal(Map<String, Object?> values) async {
    final db = await database;
    return db.insert('goals', values);
  }

  Future<int> updateGoal(int id, Map<String, Object?> values) async {
    final db = await database;
    return db.update('goals', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteGoal(int id) async {
    final db = await database;
    return db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countUsers() async {
    final db = await database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM users'),
        ) ??
        0;
  }

  Future<Map<String, Object?>?> getUserByEmail(String emailLower) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'email_lower = ?',
      whereArgs: [emailLower],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, Object?>?> getUserById(int id) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> insertUser(Map<String, Object?> values) async {
    final db = await database;
    return db.insert('users', values);
  }
}
