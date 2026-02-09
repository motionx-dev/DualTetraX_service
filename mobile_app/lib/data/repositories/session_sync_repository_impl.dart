import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/usage_session.dart';
import '../../domain/repositories/session_sync_repository.dart';
import '../datasources/session_remote_data_source.dart';
import '../models/session_upload_model.dart';

class SessionSyncRepositoryImpl implements SessionSyncRepository {
  final SessionRemoteDataSource remoteDataSource;

  SessionSyncRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, SessionUploadResult>> uploadSessions({
    required String deviceId,
    required List<UsageSession> sessions,
  }) async {
    try {
      int totalUploaded = 0;
      int totalDuplicates = 0;
      int totalErrors = 0;

      // Batch upload max 100 sessions at a time
      for (var i = 0; i < sessions.length; i += 100) {
        final batch = sessions.sublist(i, i + 100 > sessions.length ? sessions.length : i + 100);
        final uploadModel = SessionUploadModel(
          deviceId: deviceId,
          sessions: batch.map((s) => SessionItemModel.fromEntity(s)).toList(),
        );

        final response = await remoteDataSource.uploadSessions(uploadModel);
        totalUploaded += response.uploaded;
        totalDuplicates += response.duplicates;
        totalErrors += response.errors;
      }

      return Right(SessionUploadResult(
        uploaded: totalUploaded,
        duplicates: totalDuplicates,
        errors: totalErrors,
      ));
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to upload sessions', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
