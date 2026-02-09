import 'package:equatable/equatable.dart';

abstract class CloudSyncEvent extends Equatable {
  const CloudSyncEvent();
  @override
  List<Object?> get props => [];
}

class SyncToServerRequested extends CloudSyncEvent {
  const SyncToServerRequested();
}

class CloudSyncStatusChecked extends CloudSyncEvent {
  const CloudSyncStatusChecked();
}
