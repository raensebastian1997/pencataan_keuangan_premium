class UserAccount {
  const UserAccount({
    required this.id,
    required this.fullName,
    required this.email,
    required this.createdAt,
  });

  final int id;
  final String fullName;
  final String email;
  final DateTime createdAt;
}
