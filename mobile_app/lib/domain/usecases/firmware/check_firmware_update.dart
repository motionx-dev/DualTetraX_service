import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/firmware_update.dart';
import '../../repositories/server_firmware_repository.dart';

class CheckFirmwareUpdate extends UseCase<FirmwareUpdate, int> {
  final ServerFirmwareRepository repository;
  CheckFirmwareUpdate(this.repository);

  @override
  Future<Either<Failure, FirmwareUpdate>> call(int currentVersionCode) {
    return repository.checkForUpdate(currentVersionCode: currentVersionCode);
  }
}
