import '../entities/user_account.dart';

abstract class AuthRepository {
  Future<bool> hasUsers();
  Future<UserAccount?> getSessionUser();
  Future<UserAccount> register({
    required String fullName,
    required String email,
    required String password,
  });
  Future<UserAccount?> login({
    required String email,
    required String password,
  });
  Future<void> logout();
}
