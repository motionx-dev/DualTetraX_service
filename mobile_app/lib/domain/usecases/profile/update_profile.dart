import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/user_profile.dart';
import '../../repositories/profile_repository.dart';

class UpdateProfile extends UseCase<UserProfile, UpdateProfileParams> {
  final ProfileRepository repository;
  UpdateProfile(this.repository);

  @override
  Future<Either<Failure, UserProfile>> call(UpdateProfileParams params) {
    return repository.updateProfile(
      name: params.name,
      gender: params.gender,
      dateOfBirth: params.dateOfBirth,
      timezone: params.timezone,
    );
  }
}

class UpdateProfileParams {
  final String? name;
  final String? gender;
  final String? dateOfBirth;
  final String? timezone;

  const UpdateProfileParams({this.name, this.gender, this.dateOfBirth, this.timezone});
}
