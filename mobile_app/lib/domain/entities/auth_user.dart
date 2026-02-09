import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? role;

  const AuthUser({
    required this.id,
    required this.email,
    this.name,
    this.role,
  });

  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props => [id, email, name, role];
}
