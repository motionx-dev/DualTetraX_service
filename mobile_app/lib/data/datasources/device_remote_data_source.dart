import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/server_device_model.dart';

abstract class DeviceRemoteDataSource {
  Future<List<ServerDeviceModel>> getDevices();
  Future<ServerDeviceModel> registerDevice({
    required String serialNumber,
    String? modelName,
    String? firmwareVersion,
    String? bleMacAddress,
  });
  Future<ServerDeviceModel> getDevice(String id);
  Future<ServerDeviceModel> updateDevice(String id, {String? nickname, String? firmwareVersion});
  Future<void> deleteDevice(String id);
}

class DeviceRemoteDataSourceImpl implements DeviceRemoteDataSource {
  final ApiClient _apiClient;

  DeviceRemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<ServerDeviceModel>> getDevices() async {
    final response = await _apiClient.get(ApiEndpoints.devices);
    final data = response.data as Map<String, dynamic>;
    final devices = data['devices'] as List;
    return devices
        .map((d) => ServerDeviceModel.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ServerDeviceModel> registerDevice({
    required String serialNumber,
    String? modelName,
    String? firmwareVersion,
    String? bleMacAddress,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.devices,
      data: {
        'serial_number': serialNumber,
        if (modelName != null) 'model_name': modelName,
        if (firmwareVersion != null) 'firmware_version': firmwareVersion,
        if (bleMacAddress != null) 'ble_mac_address': bleMacAddress,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return ServerDeviceModel.fromJson(data['device'] as Map<String, dynamic>);
  }

  @override
  Future<ServerDeviceModel> getDevice(String id) async {
    final response = await _apiClient.get(ApiEndpoints.device(id));
    final data = response.data as Map<String, dynamic>;
    return ServerDeviceModel.fromJson(data['device'] as Map<String, dynamic>);
  }

  @override
  Future<ServerDeviceModel> updateDevice(String id, {String? nickname, String? firmwareVersion}) async {
    final response = await _apiClient.put(
      ApiEndpoints.device(id),
      data: {
        if (nickname != null) 'nickname': nickname,
        if (firmwareVersion != null) 'firmware_version': firmwareVersion,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return ServerDeviceModel.fromJson(data['device'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteDevice(String id) async {
    await _apiClient.delete(ApiEndpoints.device(id));
  }
}
