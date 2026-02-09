import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/session_upload_model.dart';

class SessionUploadResponse {
  final int uploaded;
  final int duplicates;
  final int errors;

  const SessionUploadResponse({
    this.uploaded = 0,
    this.duplicates = 0,
    this.errors = 0,
  });
}

abstract class SessionRemoteDataSource {
  Future<SessionUploadResponse> uploadSessions(SessionUploadModel uploadModel);
}

class SessionRemoteDataSourceImpl implements SessionRemoteDataSource {
  final ApiClient _apiClient;

  SessionRemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<SessionUploadResponse> uploadSessions(SessionUploadModel uploadModel) async {
    final response = await _apiClient.post(
      ApiEndpoints.sessionsUpload,
      data: uploadModel.toJson(),
    );
    final data = response.data as Map<String, dynamic>;
    return SessionUploadResponse(
      uploaded: data['uploaded'] as int? ?? 0,
      duplicates: data['duplicates'] as int? ?? 0,
      errors: data['errors'] as int? ?? 0,
    );
  }
}
