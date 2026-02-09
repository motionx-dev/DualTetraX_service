import 'package:equatable/equatable.dart';
import '../../../domain/entities/server_device.dart';

abstract class ServerDeviceState extends Equatable {
  const ServerDeviceState();
  @override
  List<Object?> get props => [];
}

class ServerDeviceInitial extends ServerDeviceState {
  const ServerDeviceInitial();
}

class ServerDeviceLoading extends ServerDeviceState {
  const ServerDeviceLoading();
}

class ServerDevicesLoaded extends ServerDeviceState {
  final List<ServerDevice> devices;
  const ServerDevicesLoaded(this.devices);
  @override
  List<Object?> get props => [devices];
}

class ServerDeviceRegistered extends ServerDeviceState {
  final ServerDevice device;
  const ServerDeviceRegistered(this.device);
  @override
  List<Object?> get props => [device];
}

class ServerDeviceError extends ServerDeviceState {
  final String message;
  const ServerDeviceError(this.message);
  @override
  List<Object?> get props => [message];
}
