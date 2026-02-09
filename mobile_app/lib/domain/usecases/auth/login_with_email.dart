import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/auth_user.dart';
import '../../repositories/auth_repository.dart';

class LoginWithEmail extends UseCase<AuthUser, LoginParams> {
  final AuthRepository repository;
  LoginWithEmail(this.repository);

  @override
  Future<Either<Failure, AuthUser>> call(LoginParams params) {
    return repository.loginWithEmail(params.email, params.password);
  }
}

class LoginParams {
  final String email;
  final String password;
  const LoginParams({required this.email, required this.password});
}
