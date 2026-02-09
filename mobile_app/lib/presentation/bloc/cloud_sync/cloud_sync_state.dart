import 'package:equatable/equatable.dart';

abstract class CloudSyncState extends Equatable {
  const CloudSyncState();
  @override
  List<Object?> get props => [];
}

class CloudSyncInitial extends CloudSyncState {
  const CloudSyncInitial();
}

class CloudSyncing extends CloudSyncState {
  const CloudSyncing();
}

class CloudSyncSuccess extends CloudSyncState {
  final int uploaded;
  final int duplicates;
  const CloudSyncSuccess({this.uploaded = 0, this.duplicates = 0});
  @override
  List<Object?> get props => [uploaded, duplicates];
}

class CloudSyncError extends CloudSyncState {
  final String message;
  const CloudSyncError(this.message);
  @override
  List<Object?> get props => [message];
}

class CloudSyncNoData extends CloudSyncState {
  const CloudSyncNoData();
}
