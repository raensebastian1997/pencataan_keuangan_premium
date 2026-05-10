import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local_database.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._database, this._preferences);

  final LocalDatabase _database;
  final SharedPreferences _preferences;

  @override
  Future<bool> hasUsers() async {
    final total = await _database.countUsers();
    return total > 0;
  }

  @override
  Future<UserAccount?> getSessionUser() async {
    final sessionUserId = _preferences.getInt(AppConstants.authSessionUserIdKey);
    if (sessionUserId == null) {
      return null;
    }
    final row = await _database.getUserById(sessionUserId);
    if (row == null) {
      await _preferences.remove(AppConstants.authSessionUserIdKey);
      return null;
    }
    return UserModel.fromMap(row);
  }

  @override
  Future<UserAccount> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final existing = await _database.getUserByEmail(normalizedEmail);
    if (existing != null) {
      throw Exception('Email sudah terdaftar. Gunakan email lain atau login.');
    }

    final insertedId = await _database.insertUser({
      'full_name': fullName.trim(),
      'email': email.trim(),
      'email_lower': normalizedEmail,
      'password_hash': _hashPassword(password),
      'created_at': DateTime.now().toIso8601String(),
    });

    final created = await _database.getUserById(insertedId);
    if (created == null) {
      throw Exception('Gagal membuat akun. Silakan coba lagi.');
    }
    await _preferences.setInt(AppConstants.authSessionUserIdKey, insertedId);
    return UserModel.fromMap(created);
  }

  @override
  Future<UserAccount?> login({
    required String email,
    required String password,
  }) async {
    final row = await _database.getUserByEmail(email.trim().toLowerCase());
    if (row == null) {
      return null;
    }
    final user = UserModel.fromMap(row);
    if (_hashPassword(password) != user.passwordHash) {
      return null;
    }
    await _preferences.setInt(AppConstants.authSessionUserIdKey, user.id);
    return user;
  }

  @override
  Future<void> logout() async {
    await _preferences.remove(AppConstants.authSessionUserIdKey);
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
}
