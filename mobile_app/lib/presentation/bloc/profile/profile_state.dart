import 'package:equatable/equatable.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/entities/skin_profile.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  final SkinProfile? skinProfile;

  const ProfileLoaded({required this.profile, this.skinProfile});

  @override
  List<Object?> get props => [profile, skinProfile];

  ProfileLoaded copyWith({UserProfile? profile, SkinProfile? skinProfile}) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      skinProfile: skinProfile ?? this.skinProfile,
    );
  }
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}
