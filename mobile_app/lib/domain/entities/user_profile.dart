import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? timezone;

  const UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.gender,
    this.dateOfBirth,
    this.timezone,
  });

  @override
  List<Object?> get props => [id, email, name, gender, dateOfBirth, timezone];
}
