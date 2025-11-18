import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_info_model.dart';

abstract class DeviceLocalDataSource {
  Future<DeviceInfoModel?> getSavedDeviceInfo();
  Future<void> saveDeviceInfo(DeviceInfoModel deviceInfo);
  Future<void> clearDeviceInfo();
}

class DeviceLocalDataSourceImpl implements DeviceLocalDataSource {
  static const String _deviceInfoKey = 'saved_device_info';
  final SharedPreferences sharedPreferences;

  DeviceLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<DeviceInfoModel?> getSavedDeviceInfo() async {
    final jsonString = sharedPreferences.getString(_deviceInfoKey);
    if (jsonString == null) return null;

    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return DeviceInfoModel.fromJson(json);
  }

  @override
  Future<void> saveDeviceInfo(DeviceInfoModel deviceInfo) async {
    final jsonString = jsonEncode(deviceInfo.toJson());
    await sharedPreferences.setString(_deviceInfoKey, jsonString);
  }

  @override
  Future<void> clearDeviceInfo() async {
    await sharedPreferences.remove(_deviceInfoKey);
  }
}
