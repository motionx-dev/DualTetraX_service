import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/auth_user.dart';
import '../../repositories/auth_repository.dart';

class SignupWithEmail extends UseCase<AuthUser, SignupParams> {
  final AuthRepository repository;
  SignupWithEmail(this.repository);

  @override
  Future<Either<Failure, AuthUser>> call(SignupParams params) {
    return repository.signupWithEmail(params.email, params.password);
  }
}

class SignupParams {
  final String email;
  final String password;
  const SignupParams({required this.email, required this.password});
}
