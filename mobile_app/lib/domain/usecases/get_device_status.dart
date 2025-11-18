import '../entities/device_status.dart';
import '../repositories/device_repository.dart';
import '../../core/usecases/usecase.dart';

class GetDeviceStatus extends StreamUseCase<DeviceStatus, NoParams> {
  final DeviceRepository repository;

  GetDeviceStatus(this.repository);

  @override
  Stream<DeviceStatus> call(NoParams params) {
    return repository.deviceStatusStream;
  }
}
