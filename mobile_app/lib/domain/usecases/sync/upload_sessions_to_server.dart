import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/sync_status.dart';
import '../../repositories/session_sync_repository.dart';
import '../../repositories/usage_repository.dart';
import '../../../data/datasources/usage_local_data_source.dart';

class UploadSessionsToServer extends UseCase<SessionUploadResult, UploadSessionsParams> {
  final SessionSyncRepository sessionSyncRepository;
  final UsageRepository usageRepository;
  final UsageLocalDataSource usageLocalDataSource;

  UploadSessionsToServer({
    required this.sessionSyncRepository,
    required this.usageRepository,
    required this.usageLocalDataSource,
  });

  @override
  Future<Either<Failure, SessionUploadResult>> call(UploadSessionsParams params) async {
    try {
      final sessions = await usageLocalDataSource.getSessionsBySyncStatus(
        SyncStatus.syncedToApp,
      );

      if (sessions.isEmpty) {
        return const Right(SessionUploadResult());
      }

      int totalUploaded = 0;
      int totalDuplicates = 0;
      int totalErrors = 0;

      // Batch upload in groups of 100
      for (var i = 0; i < sessions.length; i += 100) {
        final batch = sessions.sublist(
          i,
          i + 100 > sessions.length ? sessions.length : i + 100,
        );

        final result = await sessionSyncRepository.uploadSessions(
          deviceId: params.serverDeviceId,
          sessions: batch,
        );

        result.fold(
          (failure) {
            totalErrors += batch.length;
          },
          (uploadResult) {
            totalUploaded += uploadResult.uploaded;
            totalDuplicates += uploadResult.duplicates;
            totalErrors += uploadResult.errors;

            // Update sync status for successfully uploaded sessions
            for (final session in batch) {
              usageRepository.updateSyncStatus(
                session.uuid,
                SyncStatus.syncedToServer,
              );
            }
          },
        );
      }

      return Right(SessionUploadResult(
        uploaded: totalUploaded,
        duplicates: totalDuplicates,
        errors: totalErrors,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class UploadSessionsParams {
  final String serverDeviceId;
  const UploadSessionsParams({required this.serverDeviceId});
}
