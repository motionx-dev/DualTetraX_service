import 'package:equatable/equatable.dart';

abstract class DeviceSyncState extends Equatable {
  const DeviceSyncState();

  @override
  List<Object?> get props => [];
}

class DeviceSyncInitial extends DeviceSyncState {}

class DeviceSyncTimeSyncing extends DeviceSyncState {}

class DeviceSyncTimeSynced extends DeviceSyncState {}

class DeviceSyncTimeSyncFailed extends DeviceSyncState {
  final String message;

  const DeviceSyncTimeSyncFailed(this.message);

  @override
  List<Object?> get props => [message];
}

class DeviceSyncSessionSyncing extends DeviceSyncState {
  final int totalSessions;
  final int syncedSessions;

  const DeviceSyncSessionSyncing({
    required this.totalSessions,
    required this.syncedSessions,
  });

  int get progress => totalSessions > 0
      ? ((syncedSessions / totalSessions) * 100).round()
      : 0;

  @override
  List<Object?> get props => [totalSessions, syncedSessions];
}

class DeviceSyncSessionComplete extends DeviceSyncState {
  final int syncedCount;

  const DeviceSyncSessionComplete(this.syncedCount);

  @override
  List<Object?> get props => [syncedCount];
}

class DeviceSyncSessionFailed extends DeviceSyncState {
  final String message;

  const DeviceSyncSessionFailed(this.message);

  @override
  List<Object?> get props => [message];
}

class DeviceSyncActiveSession extends DeviceSyncState {
  final String uuid;
  final int shotType;
  final int mode;
  final int level;

  const DeviceSyncActiveSession({
    required this.uuid,
    required this.shotType,
    required this.mode,
    required this.level,
  });

  @override
  List<Object?> get props => [uuid, shotType, mode, level];
}
