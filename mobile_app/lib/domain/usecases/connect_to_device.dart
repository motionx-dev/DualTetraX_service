import 'package:dartz/dartz.dart';
import '../repositories/device_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

class ConnectToDevice extends UseCase<void, NoParams> {
  final DeviceRepository repository;

  ConnectToDevice(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.scanAndConnect();
  }
}
