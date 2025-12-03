import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../domain/entities/device_info.dart';
import '../../domain/entities/device_status.dart';
import '../../domain/entities/connection_state.dart';
import '../../domain/entities/working_state.dart';
import '../../domain/repositories/device_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/ble_remote_data_source.dart';
import '../datasources/device_local_data_source.dart';
import '../models/device_info_model.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final BleRemoteDataSource remoteDataSource;
  final DeviceLocalDataSource localDataSource;

  WorkingState? _lastWorkingState;
  StreamSubscription? _statusSubscription;

  DeviceRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  }) {
    _statusSubscription = remoteDataSource.deviceStatusStream.listen((status) {
      _lastWorkingState = status.workingState;
    });
  }

  @override
  WorkingState? get lastWorkingState => _lastWorkingState;

  @override
  Stream<BleConnectionState> get connectionStateStream =>
      remoteDataSource.connectionStateStream;

  @override
  Stream<DeviceStatus> get deviceStatusStream =>
      remoteDataSource.deviceStatusStream;

  @override
  Future<Either<Failure, void>> scanAndConnect() async {
    try {
      await remoteDataSource.scanAndConnect();
      return const Right(null);
    } on Exception catch (e) {
      return Left(BleFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> connectToDevice(String deviceId) async {
    try {
      await remoteDataSource.connectToDevice(deviceId);
      return const Right(null);
    } on Exception catch (e) {
      return Left(ConnectionFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> disconnect() async {
    try {
      await remoteDataSource.disconnect();
      return const Right(null);
    } on Exception catch (e) {
      return Left(BleFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DeviceInfo>> getDeviceInfo() async {
    try {
      final deviceInfo = await remoteDataSource.getDeviceInfo();
      return Right(deviceInfo);
    } on Exception catch (e) {
      return Left(BleFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DeviceInfo?>> getSavedDeviceInfo() async {
    try {
      final deviceInfo = await localDataSource.getSavedDeviceInfo();
      return Right(deviceInfo);
    } on Exception catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveDeviceInfo(DeviceInfo deviceInfo) async {
    try {
      final model = DeviceInfoModel.fromEntity(deviceInfo);
      await localDataSource.saveDeviceInfo(model);
      return const Right(null);
    } on Exception catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DeviceStatus>> getCurrentStatus() async {
    try {
      final status = await remoteDataSource.getCurrentStatus();
      return Right(status);
    } on Exception catch (e) {
      return Left(BleFailure(e.toString()));
    }
  }

  @override
  Future<void> refreshStatus() async {
    await remoteDataSource.refreshStatus();
  }
}
