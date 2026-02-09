import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/profile/get_profile.dart';
import '../../../domain/usecases/profile/update_profile.dart' as update_usecase;
import '../../../domain/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfile getProfile;
  final update_usecase.UpdateProfile updateProfileUseCase;
  final ProfileRepository profileRepository;

  ProfileBloc({
    required this.getProfile,
    required this.updateProfileUseCase,
    required this.profileRepository,
  }) : super(const ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<LoadSkinProfile>(_onLoadSkinProfile);
    on<UpdateSkinProfile>(_onUpdateSkinProfile);
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    final result = await getProfile(NoParams());
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (profile) => emit(ProfileLoaded(profile: profile)),
    );
  }

  Future<void> _onUpdateProfile(UpdateProfile event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    final result = await updateProfileUseCase(update_usecase.UpdateProfileParams(
      name: event.name,
      gender: event.gender,
      dateOfBirth: event.dateOfBirth,
      timezone: event.timezone,
    ));
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (profile) {
        final currentState = state;
        if (currentState is ProfileLoaded) {
          emit(currentState.copyWith(profile: profile));
        } else {
          emit(ProfileLoaded(profile: profile));
        }
      },
    );
  }

  Future<void> _onLoadSkinProfile(LoadSkinProfile event, Emitter<ProfileState> emit) async {
    final result = await profileRepository.getSkinProfile();
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (skinProfile) {
        final currentState = state;
        if (currentState is ProfileLoaded) {
          emit(currentState.copyWith(skinProfile: skinProfile));
        }
      },
    );
  }

  Future<void> _onUpdateSkinProfile(UpdateSkinProfile event, Emitter<ProfileState> emit) async {
    final result = await profileRepository.updateSkinProfile(
      skinType: event.skinType,
      concerns: event.concerns,
      memo: event.memo,
    );
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (skinProfile) {
        final currentState = state;
        if (currentState is ProfileLoaded) {
          emit(currentState.copyWith(skinProfile: skinProfile));
        }
      },
    );
  }
}
