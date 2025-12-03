import 'package:equatable/equatable.dart';

abstract class DeviceConnectionEvent extends Equatable {
  const DeviceConnectionEvent();

  @override
  List<Object?> get props => [];
}

class ConnectRequested extends DeviceConnectionEvent {}

class DisconnectRequested extends DeviceConnectionEvent {}

class ConnectionStateChanged extends DeviceConnectionEvent {
  final bool isConnected;

  const ConnectionStateChanged(this.isConnected);

  @override
  List<Object?> get props => [isConnected];
}

class AutoReconnectSettingsChanged extends DeviceConnectionEvent {
  final bool? enabled;
  final int? intervalSeconds;

  const AutoReconnectSettingsChanged({this.enabled, this.intervalSeconds});

  @override
  List<Object?> get props => [enabled, intervalSeconds];
}
