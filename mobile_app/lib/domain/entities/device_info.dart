import 'package:equatable/equatable.dart';

class DeviceInfo extends Equatable {
  final String deviceId;
  final String deviceName;
  final String firmwareVersion;
  final String modelName;
  final String serialNumber;
  final String? bleAddress;

  const DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.firmwareVersion,
    required this.modelName,
    required this.serialNumber,
    this.bleAddress,
  });

  @override
  List<Object?> get props => [
        deviceId,
        deviceName,
        firmwareVersion,
        modelName,
        serialNumber,
        bleAddress,
      ];
}
