import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  const LoadProfile();
}

class UpdateProfile extends ProfileEvent {
  final String? name;
  final String? gender;
  final String? dateOfBirth;
  final String? timezone;

  const UpdateProfile({this.name, this.gender, this.dateOfBirth, this.timezone});

  @override
  List<Object?> get props => [name, gender, dateOfBirth, timezone];
}

class LoadSkinProfile extends ProfileEvent {
  const LoadSkinProfile();
}

class UpdateSkinProfile extends ProfileEvent {
  final String? skinType;
  final List<String>? concerns;
  final String? memo;

  const UpdateSkinProfile({this.skinType, this.concerns, this.memo});

  @override
  List<Object?> get props => [skinType, concerns, memo];
}
