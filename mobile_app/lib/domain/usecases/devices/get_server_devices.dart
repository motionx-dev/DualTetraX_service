import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/server_device.dart';
import '../../repositories/server_device_repository.dart';

class GetServerDevices extends UseCase<List<ServerDevice>, NoParams> {
  final ServerDeviceRepository repository;
  GetServerDevices(this.repository);

  @override
  Future<Either<Failure, List<ServerDevice>>> call(NoParams params) {
    return repository.getDevices();
  }
}
