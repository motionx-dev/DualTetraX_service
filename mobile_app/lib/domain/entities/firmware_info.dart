import 'package:equatable/equatable.dart';

/// Firmware information entity for OTA updates
class FirmwareInfo extends Equatable {
  final String name;
  final String version;
  final int size; // bytes
  final String? path; // local file path (for local firmware)
  final String? url; // download URL (for server firmware)
  final String? md5; // checksum
  final DateTime? releaseDate;

  const FirmwareInfo({
    required this.name,
    required this.version,
    required this.size,
    this.path,
    this.url,
    this.md5,
    this.releaseDate,
  });

  factory FirmwareInfo.fromLocalFile({
    required String path,
    required int size,
    String? name,
    String? version,
    String? md5,
  }) {
    final fileName = path.split('/').last;
    return FirmwareInfo(
      name: name ?? fileName,
      version: version ?? _extractVersion(fileName),
      size: size,
      path: path,
      md5: md5,
    );
  }

  /// Extract version from filename (e.g., "firmware-v1.0.0.bin" -> "v1.0.0")
  static String _extractVersion(String fileName) {
    final versionRegex = RegExp(r'v?\d+\.\d+\.\d+');
    final match = versionRegex.firstMatch(fileName);
    return match?.group(0) ?? 'unknown';
  }

  /// Get size in human-readable format
  String get sizeFormatted {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  /// Calculate chunk count for BLE transfer
  int get chunkCount {
    const chunkSize = 240; // Max chunk payload size from firmware
    return (size / chunkSize).ceil();
  }

  bool get isLocal => path != null;
  bool get isRemote => url != null;

  @override
  List<Object?> get props => [name, version, size, path, url, md5, releaseDate];
}
