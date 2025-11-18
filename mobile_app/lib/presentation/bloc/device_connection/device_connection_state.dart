import 'package:equatable/equatable.dart';
import '../../../domain/entities/connection_state.dart';

abstract class DeviceConnectionState extends Equatable {
  const DeviceConnectionState();

  @override
  List<Object?> get props => [];
}

class DeviceConnectionInitial extends DeviceConnectionState {}

class DeviceConnecting extends DeviceConnectionState {}

class DeviceConnected extends DeviceConnectionState {}

class DeviceDisconnected extends DeviceConnectionState {
  final String? message;

  const DeviceDisconnected({this.message});

  @override
  List<Object?> get props => [message];
}

class DeviceConnectionError extends DeviceConnectionState {
  final String message;

  const DeviceConnectionError(this.message);

  @override
  List<Object?> get props => [message];
}
