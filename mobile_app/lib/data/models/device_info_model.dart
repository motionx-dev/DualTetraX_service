import '../../domain/entities/device_info.dart';

class DeviceInfoModel extends DeviceInfo {
  const DeviceInfoModel({
    required super.deviceId,
    required super.deviceName,
    required super.firmwareVersion,
    required super.modelName,
    required super.serialNumber,
    super.bleAddress,
  });

  factory DeviceInfoModel.fromJson(Map<String, dynamic> json) {
    return DeviceInfoModel(
      deviceId: json['device_id'] as String,
      deviceName: json['device_name'] as String,
      firmwareVersion: json['firmware_version'] as String,
      modelName: json['model_name'] as String,
      serialNumber: json['serial_number'] as String,
      bleAddress: json['ble_address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'firmware_version': firmwareVersion,
      'model_name': modelName,
      'serial_number': serialNumber,
      'ble_address': bleAddress,
    };
  }

  factory DeviceInfoModel.fromEntity(DeviceInfo entity) {
    return DeviceInfoModel(
      deviceId: entity.deviceId,
      deviceName: entity.deviceName,
      firmwareVersion: entity.firmwareVersion,
      modelName: entity.modelName,
      serialNumber: entity.serialNumber,
      bleAddress: entity.bleAddress,
    );
  }
}
