import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/server_device.dart';
import '../../repositories/server_device_repository.dart';

class RegisterServerDevice extends UseCase<ServerDevice, RegisterDeviceParams> {
  final ServerDeviceRepository repository;
  RegisterServerDevice(this.repository);

  @override
  Future<Either<Failure, ServerDevice>> call(RegisterDeviceParams params) {
    return repository.registerDevice(
      serialNumber: params.serialNumber,
      modelName: params.modelName,
      firmwareVersion: params.firmwareVersion,
      bleMacAddress: params.bleMacAddress,
    );
  }
}

class RegisterDeviceParams {
  final String serialNumber;
  final String? modelName;
  final String? firmwareVersion;
  final String? bleMacAddress;

  const RegisterDeviceParams({
    required this.serialNumber,
    this.modelName,
    this.firmwareVersion,
    this.bleMacAddress,
  });
}
