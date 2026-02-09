import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/firmware_update.dart';
import '../../domain/repositories/server_firmware_repository.dart';
import '../datasources/firmware_remote_data_source.dart';

class ServerFirmwareRepositoryImpl implements ServerFirmwareRepository {
  final FirmwareRemoteDataSource remoteDataSource;

  ServerFirmwareRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, FirmwareUpdate>> checkForUpdate({int currentVersionCode = 0}) async {
    try {
      final update = await remoteDataSource.checkForUpdate(currentVersionCode: currentVersionCode);
      return Right(update);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to check firmware update', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FirmwareVersion>> getLatestFirmware() async {
    try {
      final firmware = await remoteDataSource.getLatestFirmware();
      return Right(firmware);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to get latest firmware', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
