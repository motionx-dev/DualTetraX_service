import '../../domain/entities/server_device.dart';

class ServerDeviceModel extends ServerDevice {
  const ServerDeviceModel({
    required super.id,
    required super.userId,
    required super.serialNumber,
    super.modelName,
    super.firmwareVersion,
    super.bleMacAddress,
    super.nickname,
    super.isActive,
    required super.registeredAt,
    super.totalSessions,
    super.lastSyncedAt,
  });

  factory ServerDeviceModel.fromJson(Map<String, dynamic> json) {
    return ServerDeviceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      serialNumber: json['serial_number'] as String,
      modelName: json['model_name'] as String? ?? 'DualTetraX',
      firmwareVersion: json['firmware_version'] as String?,
      bleMacAddress: json['ble_mac_address'] as String?,
      nickname: json['nickname'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      registeredAt: DateTime.parse(json['registered_at'] as String),
      totalSessions: json['total_sessions'] as int? ?? 0,
      lastSyncedAt: json['last_synced_at'] != null
          ? DateTime.parse(json['last_synced_at'] as String)
          : null,
    );
  }
}
