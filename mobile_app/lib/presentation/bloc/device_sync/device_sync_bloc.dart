import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../domain/entities/connection_state.dart';
import '../../../domain/usecases/sync_device_sessions.dart';
import '../../../data/datasources/ble_comm_data_source.dart';
import 'device_sync_event.dart';
import 'device_sync_state.dart';

class DeviceSyncBloc extends Bloc<DeviceSyncEvent, DeviceSyncState> {
  final SyncDeviceSessionsUseCase syncDeviceSessionsUseCase;
  final BleCommDataSource bleCommDataSource;
  final Stream<BleConnectionState> connectionStateStream;
  final BluetoothDevice? Function() getConnectedDevice;

  StreamSubscription? _connectionSubscription;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _sessionEndSubscription;
  bool _isCommInitialized = false;

  DeviceSyncBloc({
    required this.syncDeviceSessionsUseCase,
    required this.bleCommDataSource,
    required this.connectionStateStream,
    required this.getConnectedDevice,
  }) : super(DeviceSyncInitial()) {
    on<TimeSyncRequested>(_onTimeSyncRequested);
    on<SessionSyncRequested>(_onSessionSyncRequested);
    on<SessionStartReceived>(_onSessionStartReceived);
    on<SessionEndReceived>(_onSessionEndReceived);
    on<SyncReset>(_onSyncReset);
    on<DeviceConnected>(_onDeviceConnected);
    on<DeviceDisconnected>(_onDeviceDisconnected);

    _listenToConnectionState();
  }

  void _listenToConnectionState() {
    _connectionSubscription = connectionStateStream.listen((connState) {
      if (connState == BleConnectionState.connected) {
        add(const DeviceConnected());
      } else if (connState == BleConnectionState.disconnected) {
        add(const DeviceDisconnected());
      }
    });
  }

  void _listenToStatusUpdates() {
    _statusSubscription?.cancel();
    _sessionEndSubscription?.cancel();

    // Listen to status updates for UI display only (not for session detection)
    // Session detection is handled by firmware's SESSION_END notification
    _statusSubscription = bleCommDataSource.statusUpdates.listen((status) {
      final currentState = state;

      // Update UI state for active session display (informational only)
      if (status.isSessionActive) {
        if (currentState is! DeviceSyncActiveSession ||
            currentState.shotType != status.shotType ||
            currentState.mode != status.mode) {
          // Update UI to show current active session info
          add(SessionStartReceived(
            uuid: '',
            shotType: status.shotType,
            mode: status.mode,
            level: status.level,
          ));
        }
      } else if (currentState is DeviceSyncActiveSession) {
        // Session no longer active - return to time synced state
        // Actual session sync will be triggered by SESSION_END notification from firmware
        add(const SyncReset());
      }
    });

    // Listen to dedicated session end notifications from firmware for reliable sync
    // This is the authoritative source for session completion
    _sessionEndSubscription = bleCommDataSource.sessionEndStream.listen((notification) {
      // Firmware sent SESSION_END - trigger sync to get the completed session
      add(SessionEndReceived(uuid: notification.uuid));
    });
  }

  Future<void> _onDeviceConnected(
    DeviceConnected event,
    Emitter<DeviceSyncState> emit,
  ) async {
    final device = getConnectedDevice();
    if (device == null) {
      emit(const DeviceSyncTimeSyncFailed('No device connected'));
      return;
    }

    emit(DeviceSyncTimeSyncing());

    try {
      await bleCommDataSource.initialize(device);
      _isCommInitialized = true;
      _listenToStatusUpdates();

      // Send time sync
      final now = DateTime.now().millisecondsSinceEpoch;
      final result = await bleCommDataSource.sendTimeSync(now);

      if (result == ResponseStatus.success) {
        emit(DeviceSyncTimeSynced());

        // Automatically sync any missed sessions from device
        // This catches sessions that occurred while the app was disconnected
        final syncResult = await syncDeviceSessionsUseCase.syncAllSessions();
        syncResult.fold(
          (failure) {
            // Sync failed, but time sync succeeded - stay in time synced state
          },
          (syncedCount) {
            if (syncedCount > 0) {
              emit(DeviceSyncSessionComplete(syncedCount));
            }
          },
        );
      } else {
        emit(DeviceSyncTimeSyncFailed('Time sync failed: ${result.name}'));
      }
    } catch (e) {
      emit(DeviceSyncTimeSyncFailed(e.toString()));
    }
  }

  Future<void> _onDeviceDisconnected(
    DeviceDisconnected event,
    Emitter<DeviceSyncState> emit,
  ) async {
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _sessionEndSubscription?.cancel();
    _sessionEndSubscription = null;

    if (_isCommInitialized) {
      await bleCommDataSource.disconnect();
      _isCommInitialized = false;
    }

    emit(DeviceSyncInitial());
  }

  Future<void> _onTimeSyncRequested(
    TimeSyncRequested event,
    Emitter<DeviceSyncState> emit,
  ) async {
    emit(DeviceSyncTimeSyncing());

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final result = await bleCommDataSource.sendTimeSync(now);

      if (result == ResponseStatus.success) {
        emit(DeviceSyncTimeSynced());
      } else {
        emit(DeviceSyncTimeSyncFailed('Time sync failed: ${result.name}'));
      }
    } catch (e) {
      emit(DeviceSyncTimeSyncFailed(e.toString()));
    }
  }

  Future<void> _onSessionSyncRequested(
    SessionSyncRequested event,
    Emitter<DeviceSyncState> emit,
  ) async {
    emit(const DeviceSyncSessionSyncing(totalSessions: 0, syncedSessions: 0));

    try {
      // Use the use case to sync all sessions (handles parsing and DB save)
      final result = await syncDeviceSessionsUseCase.syncAllSessions();

      result.fold(
        (failure) => emit(DeviceSyncSessionFailed(failure.message)),
        (syncedCount) => emit(DeviceSyncSessionComplete(syncedCount)),
      );
    } catch (e) {
      emit(DeviceSyncSessionFailed(e.toString()));
    }
  }

  void _onSessionStartReceived(
    SessionStartReceived event,
    Emitter<DeviceSyncState> emit,
  ) {
    emit(DeviceSyncActiveSession(
      uuid: event.uuid,
      shotType: event.shotType,
      mode: event.mode,
      level: event.level,
    ));
  }

  Future<void> _onSessionEndReceived(
    SessionEndReceived event,
    Emitter<DeviceSyncState> emit,
  ) async {
    // After session ends, automatically sync sessions from device
    emit(const DeviceSyncSessionSyncing(totalSessions: 0, syncedSessions: 0));

    try {
      final result = await syncDeviceSessionsUseCase.syncAllSessions();

      result.fold(
        (failure) {
          // On failure, just go back to time synced state
          emit(DeviceSyncTimeSynced());
        },
        (syncedCount) {
          // Emit complete then go back to time synced
          emit(DeviceSyncSessionComplete(syncedCount));
        },
      );
    } catch (e) {
      emit(DeviceSyncTimeSynced());
    }
  }

  void _onSyncReset(
    SyncReset event,
    Emitter<DeviceSyncState> emit,
  ) {
    // Return to time synced state (not initial - we're still connected)
    emit(DeviceSyncTimeSynced());
  }

  @override
  Future<void> close() {
    _connectionSubscription?.cancel();
    _statusSubscription?.cancel();
    _sessionEndSubscription?.cancel();
    if (_isCommInitialized) {
      bleCommDataSource.disconnect();
    }
    return super.close();
  }
}
