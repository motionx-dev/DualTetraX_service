import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/server_device.dart';

abstract class ServerDeviceRepository {
  Future<Either<Failure, List<ServerDevice>>> getDevices();
  Future<Either<Failure, ServerDevice>> registerDevice({
    required String serialNumber,
    String? modelName,
    String? firmwareVersion,
    String? bleMacAddress,
  });
  Future<Either<Failure, ServerDevice>> getDevice(String id);
  Future<Either<Failure, ServerDevice>> updateDevice(String id, {String? nickname, String? firmwareVersion});
  Future<Either<Failure, void>> deleteDevice(String id);
}
