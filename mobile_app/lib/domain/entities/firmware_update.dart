import 'package:equatable/equatable.dart';

class FirmwareUpdate extends Equatable {
  final bool updateAvailable;
  final FirmwareVersion? firmware;

  const FirmwareUpdate({
    required this.updateAvailable,
    this.firmware,
  });

  @override
  List<Object?> get props => [updateAvailable, firmware];
}

class FirmwareVersion extends Equatable {
  final String id;
  final String version;
  final int versionCode;
  final String? changelog;
  final String? binaryUrl;
  final int? binarySize;
  final String? binaryChecksum;
  final int? minVersionCode;
  final bool isActive;
  final DateTime createdAt;

  const FirmwareVersion({
    required this.id,
    required this.version,
    required this.versionCode,
    this.changelog,
    this.binaryUrl,
    this.binarySize,
    this.binaryChecksum,
    this.minVersionCode,
    this.isActive = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, version, versionCode, isActive];
}
