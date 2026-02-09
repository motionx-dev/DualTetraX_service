import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/usage_session.dart';

class SessionUploadResult {
  final int uploaded;
  final int duplicates;
  final int errors;

  const SessionUploadResult({
    this.uploaded = 0,
    this.duplicates = 0,
    this.errors = 0,
  });
}

abstract class SessionSyncRepository {
  Future<Either<Failure, SessionUploadResult>> uploadSessions({
    required String deviceId,
    required List<UsageSession> sessions,
  });
}
