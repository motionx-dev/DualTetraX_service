import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/user_profile.dart';
import '../../repositories/profile_repository.dart';

class GetProfile extends UseCase<UserProfile, NoParams> {
  final ProfileRepository repository;
  GetProfile(this.repository);

  @override
  Future<Either<Failure, UserProfile>> call(NoParams params) {
    return repository.getProfile();
  }
}
