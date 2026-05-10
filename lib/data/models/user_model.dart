import '../../domain/entities/user_account.dart';

class UserModel extends UserAccount {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.createdAt,
    required this.passwordHash,
  });

  final String passwordHash;

  factory UserModel.fromMap(Map<String, Object?> map) {
    return UserModel(
      id: map['id'] as int,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      passwordHash: map['password_hash'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'email_lower': email.toLowerCase(),
      'password_hash': passwordHash,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
