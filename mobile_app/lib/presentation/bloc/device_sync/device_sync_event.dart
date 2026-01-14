import 'package:equatable/equatable.dart';

abstract class DeviceSyncEvent extends Equatable {
  const DeviceSyncEvent();

  @override
  List<Object?> get props => [];
}

class TimeSyncRequested extends DeviceSyncEvent {
  const TimeSyncRequested();
}

class SessionSyncRequested extends DeviceSyncEvent {
  const SessionSyncRequested();
}

class SessionStartReceived extends DeviceSyncEvent {
  final String uuid;
  final int shotType;
  final int mode;
  final int level;

  const SessionStartReceived({
    required this.uuid,
    required this.shotType,
    required this.mode,
    required this.level,
  });

  @override
  List<Object?> get props => [uuid, shotType, mode, level];
}

class SessionEndReceived extends DeviceSyncEvent {
  final String uuid;

  const SessionEndReceived({required this.uuid});

  @override
  List<Object?> get props => [uuid];
}

class SyncReset extends DeviceSyncEvent {
  const SyncReset();
}

class DeviceConnected extends DeviceSyncEvent {
  const DeviceConnected();
}

class DeviceDisconnected extends DeviceSyncEvent {
  const DeviceDisconnected();
}
