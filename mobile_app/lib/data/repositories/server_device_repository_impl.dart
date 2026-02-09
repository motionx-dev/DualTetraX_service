import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/server_device.dart';
import '../../domain/repositories/server_device_repository.dart';
import '../datasources/device_remote_data_source.dart';

class ServerDeviceRepositoryImpl implements ServerDeviceRepository {
  final DeviceRemoteDataSource remoteDataSource;

  ServerDeviceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ServerDevice>>> getDevices() async {
    try {
      final devices = await remoteDataSource.getDevices();
      return Right(devices);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to get devices', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServerDevice>> registerDevice({
    required String serialNumber,
    String? modelName,
    String? firmwareVersion,
    String? bleMacAddress,
  }) async {
    try {
      final device = await remoteDataSource.registerDevice(
        serialNumber: serialNumber,
        modelName: modelName,
        firmwareVersion: firmwareVersion,
        bleMacAddress: bleMacAddress,
      );
      return Right(device);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return Left(ConflictFailure(e.response?.data?['error'] ?? 'Device already registered'));
      }
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to register device', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServerDevice>> getDevice(String id) async {
    try {
      final device = await remoteDataSource.getDevice(id);
      return Right(device);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to get device', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServerDevice>> updateDevice(String id, {String? nickname, String? firmwareVersion}) async {
    try {
      final device = await remoteDataSource.updateDevice(id, nickname: nickname, firmwareVersion: firmwareVersion);
      return Right(device);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to update device', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDevice(String id) async {
    try {
      await remoteDataSource.deleteDevice(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to delete device', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
