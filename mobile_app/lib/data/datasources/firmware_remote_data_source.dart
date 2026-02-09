import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/firmware_update_model.dart';

abstract class FirmwareRemoteDataSource {
  Future<FirmwareUpdateModel> checkForUpdate({int currentVersionCode = 0});
  Future<FirmwareVersionModel> getLatestFirmware();
}

class FirmwareRemoteDataSourceImpl implements FirmwareRemoteDataSource {
  final ApiClient _apiClient;

  FirmwareRemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<FirmwareUpdateModel> checkForUpdate({int currentVersionCode = 0}) async {
    final response = await _apiClient.get(
      ApiEndpoints.firmwareCheck,
      queryParameters: {'current_version_code': currentVersionCode},
    );
    return FirmwareUpdateModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<FirmwareVersionModel> getLatestFirmware() async {
    final response = await _apiClient.get(ApiEndpoints.firmwareLatest);
    final data = response.data as Map<String, dynamic>;
    return FirmwareVersionModel.fromJson(data['firmware'] as Map<String, dynamic>);
  }
}
