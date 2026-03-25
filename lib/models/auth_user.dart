class AuthUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? token;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.token,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json, {String? token}) {
    return AuthUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      token: token,
    );
  }
}
