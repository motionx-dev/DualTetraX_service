import 'package:dartz/dartz.dart';
import '../entities/device_info.dart';
import '../entities/device_status.dart';
import '../entities/connection_state.dart';
import '../../core/errors/failures.dart';

abstract class DeviceRepository {
  // BLE Connection
  Stream<BleConnectionState> get connectionStateStream;
  Future<Either<Failure, void>> scanAndConnect();
  Future<Either<Failure, void>> connectToDevice(String deviceId);
  Future<Either<Failure, void>> disconnect();

  // Device Info
  Future<Either<Failure, DeviceInfo>> getDeviceInfo();
  Future<Either<Failure, DeviceInfo?>> getSavedDeviceInfo();
  Future<Either<Failure, void>> saveDeviceInfo(DeviceInfo deviceInfo);

  // Device Status
  Stream<DeviceStatus> get deviceStatusStream;
  Future<Either<Failure, DeviceStatus>> getCurrentStatus();
  Future<void> refreshStatus();  // Re-read all characteristic values
}
