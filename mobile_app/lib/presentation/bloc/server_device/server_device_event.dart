import 'package:equatable/equatable.dart';

abstract class ServerDeviceEvent extends Equatable {
  const ServerDeviceEvent();
  @override
  List<Object?> get props => [];
}

class LoadServerDevices extends ServerDeviceEvent {
  const LoadServerDevices();
}

class RegisterServerDevice extends ServerDeviceEvent {
  final String serialNumber;
  final String? modelName;
  final String? firmwareVersion;
  final String? bleMacAddress;

  const RegisterServerDevice({
    required this.serialNumber,
    this.modelName,
    this.firmwareVersion,
    this.bleMacAddress,
  });

  @override
  List<Object?> get props => [serialNumber, modelName, firmwareVersion, bleMacAddress];
}
