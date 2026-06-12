class AccountInfo {
  const AccountInfo({
    required this.name,
    required this.email,
    required this.password,
    this.equipe,
  });

  final String name;
  final String email;
  final String password;
  final String? equipe;
}
