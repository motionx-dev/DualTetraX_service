import '../../domain/entities/firmware_update.dart';

class FirmwareUpdateModel extends FirmwareUpdate {
  const FirmwareUpdateModel({
    required super.updateAvailable,
    super.firmware,
  });

  factory FirmwareUpdateModel.fromJson(Map<String, dynamic> json) {
    return FirmwareUpdateModel(
      updateAvailable: json['update_available'] as bool? ?? false,
      firmware: json['firmware'] != null
          ? FirmwareVersionModel.fromJson(json['firmware'] as Map<String, dynamic>)
          : null,
    );
  }
}

class FirmwareVersionModel extends FirmwareVersion {
  const FirmwareVersionModel({
    required super.id,
    required super.version,
    required super.versionCode,
    super.changelog,
    super.binaryUrl,
    super.binarySize,
    super.binaryChecksum,
    super.minVersionCode,
    super.isActive,
    required super.createdAt,
  });

  factory FirmwareVersionModel.fromJson(Map<String, dynamic> json) {
    return FirmwareVersionModel(
      id: json['id'] as String,
      version: json['version'] as String,
      versionCode: json['version_code'] as int,
      changelog: json['changelog'] as String?,
      binaryUrl: json['binary_url'] as String?,
      binarySize: json['binary_size'] as int?,
      binaryChecksum: json['binary_checksum'] as String?,
      minVersionCode: json['min_version_code'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
