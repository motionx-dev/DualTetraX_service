import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/firmware_update.dart';

abstract class ServerFirmwareRepository {
  Future<Either<Failure, FirmwareUpdate>> checkForUpdate({int currentVersionCode = 0});
  Future<Either<Failure, FirmwareVersion>> getLatestFirmware();
}
