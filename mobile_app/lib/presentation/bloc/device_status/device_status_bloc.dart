import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/device_status.dart';
import '../../../domain/entities/working_state.dart';
import '../../../domain/entities/usage_session.dart';
import '../../../domain/entities/shot_type.dart';
import '../../../domain/entities/device_mode.dart';
import '../../../domain/entities/device_level.dart';
import '../../../domain/entities/termination_reason.dart';
import '../../../domain/entities/sync_status.dart';
import '../../../domain/usecases/get_device_status.dart';
import '../../../domain/repositories/device_repository.dart';
import '../../../domain/repositories/usage_repository.dart';
import '../../../data/datasources/ble_comm_data_source.dart';
import '../../../core/usecases/usecase.dart';

// Events
abstract class DeviceStatusEvent extends Equatable {
  const DeviceStatusEvent();

  @override
  List<Object?> get props => [];
}

class StartListeningToStatus extends DeviceStatusEvent {}

class StopListeningToStatus extends DeviceStatusEvent {}

class RefreshStatusRequested extends DeviceStatusEvent {}

class DeviceStatusUpdated extends DeviceStatusEvent {
  final DeviceStatus status;

  const DeviceStatusUpdated(this.status);

  @override
  List<Object?> get props => [status];
}

class _TimerTick extends DeviceStatusEvent {}

class _TimeoutDisplayExpired extends DeviceStatusEvent {}

// States
abstract class DeviceStatusState extends Equatable {
  const DeviceStatusState();

  @override
  List<Object?> get props => [];
}

class DeviceStatusInitial extends DeviceStatusState {}

class DeviceStatusLoaded extends DeviceStatusState {
  final DeviceStatus status;

  const DeviceStatusLoaded(this.status);

  @override
  List<Object?> get props => [status];
}

class DeviceStatusTimeoutPowerOff extends DeviceStatusState {}

// Bloc
class DeviceStatusBloc extends Bloc<DeviceStatusEvent, DeviceStatusState> {
  final GetDeviceStatus getDeviceStatus;
  final DeviceRepository deviceRepository;
  final UsageRepository usageRepository;
  final BleCommDataSource bleCommDataSource;

  StreamSubscription? _statusSubscription;
  StreamSubscription? _sessionStartSubscription;
  Timer? _workingTimer;
  Timer? _timeoutDisplayTimer;
  DateTime? _workingStartTime;
  int _elapsedSeconds = 0;
  DeviceStatus? _lastStatus;

  // Active session tracking for local save
  DateTime? _sessionStartTime;
  ShotType? _sessionShotType;
  DeviceMode? _sessionMode;
  DeviceLevel? _sessionLevel;
  int? _sessionStartBattery;
  bool _hadTempWarning = false;
  bool _hadBatteryWarning = false;
  bool _isSessionActive = false;
  String? _sessionUuid; // UUID from device (via SessionStartNotification)

  // Total operation time: 8 minutes = 480 seconds
  static const int totalOperationTime = 480;
  static const int timeoutDisplayDuration = 15;
  // Minimum working duration (seconds) to save a session
  static const int minWorkingDurationSeconds = 3;

  DeviceStatusBloc({
    required this.getDeviceStatus,
    required this.deviceRepository,
    required this.usageRepository,
    required this.bleCommDataSource,
  }) : super(DeviceStatusInitial()) {
    on<StartListeningToStatus>(_onStartListening);
    on<StopListeningToStatus>(_onStopListening);
    on<RefreshStatusRequested>(_onRefreshStatus);
    on<DeviceStatusUpdated>(_onStatusUpdated);
    on<_TimerTick>(_onTimerTick);
    on<_TimeoutDisplayExpired>(_onTimeoutDisplayExpired);
  }

  Future<void> _onStartListening(
    StartListeningToStatus event,
    Emitter<DeviceStatusState> emit,
  ) async {
    _timeoutDisplayTimer?.cancel();
    _timeoutDisplayTimer = null;

    if (_lastStatus?.workingState == WorkingState.ota ||
        _lastStatus?.workingState == WorkingState.timeout) {
      _lastStatus = null;
    }

    _statusSubscription = getDeviceStatus(NoParams()).listen((status) {
      add(DeviceStatusUpdated(status));
    });

    // Subscribe to SessionStartNotification to get device UUID
    _sessionStartSubscription = bleCommDataSource.sessionStartStream.listen((notification) {
      print('[DeviceStatusBloc] Received SessionStartNotification: uuid=${notification.uuid}');
      _sessionUuid = notification.uuid;
    });
  }

  Future<void> _onStopListening(
    StopListeningToStatus event,
    Emitter<DeviceStatusState> emit,
  ) async {
    _stopWorkingTimer();
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _sessionStartSubscription?.cancel();
    _sessionStartSubscription = null;

    // Save session if BLE connection is lost during an active session
    if (_isSessionActive && _elapsedSeconds >= minWorkingDurationSeconds) {
      await _saveAndResetSession(
        TerminationReason.other, // Connection lost
        _lastStatus?.batteryStatus.level,
      );
    }

    if (_lastStatus?.workingState == WorkingState.ota) {
      emit(DeviceStatusLoaded(_lastStatus!));
    } else if (_lastStatus?.workingState == WorkingState.timeout) {
      emit(DeviceStatusTimeoutPowerOff());
      _timeoutDisplayTimer = Timer(
        Duration(seconds: timeoutDisplayDuration),
        () => add(_TimeoutDisplayExpired()),
      );
    } else {
      _lastStatus = null;
      emit(DeviceStatusInitial());
    }
  }

  Future<void> _onTimeoutDisplayExpired(
    _TimeoutDisplayExpired event,
    Emitter<DeviceStatusState> emit,
  ) async {
    _timeoutDisplayTimer?.cancel();
    _timeoutDisplayTimer = null;
    _lastStatus = null;
    emit(DeviceStatusInitial());
  }

  Future<void> _onRefreshStatus(
    RefreshStatusRequested event,
    Emitter<DeviceStatusState> emit,
  ) async {
    // Re-read all characteristic values from BLE device
    await deviceRepository.refreshStatus();
  }

  Future<void> _onStatusUpdated(
    DeviceStatusUpdated event,
    Emitter<DeviceStatusState> emit,
  ) async {
    final status = event.status;
    _lastStatus = status;

    // Use elapsed time from device if available, otherwise use local tracking
    if (status.currentWorkingTime != null) {
      _elapsedSeconds = status.currentWorkingTime!;
      // Sync local timer's start time with device's elapsed time
      // This prevents _onTimerTick from overwriting device's elapsed time
      if (_workingTimer != null) {
        _workingStartTime = DateTime.now().subtract(Duration(seconds: _elapsedSeconds));
      }
    }

    // Track warnings during session
    if (_isSessionActive) {
      if (status.warningStatus.temperatureWarning) {
        _hadTempWarning = true;
      }
      if (status.warningStatus.batteryLowWarning || status.warningStatus.batteryCriticalWarning) {
        _hadBatteryWarning = true;
      }
    }

    // Handle working state changes for time tracking
    if (status.workingState == WorkingState.working) {
      // Start new session if not already active
      if (!_isSessionActive) {
        _startNewSession(status);
      }
      if (_workingTimer == null) {
        // Start tracking time when entering working state
        _startWorkingTimer();
      }
      // Emit status with current working time (from device or local)
      emit(DeviceStatusLoaded(status.copyWith(
        currentWorkingTime: _elapsedSeconds,
        totalWorkingTime: totalOperationTime,
      )));
    } else {
      // Stop timer when not in working state
      if (status.workingState == WorkingState.off ||
          status.workingState == WorkingState.standby) {
        // Save session before resetting if we have meaningful data
        await _saveAndResetSession(
          status.workingState == WorkingState.standby
              ? TerminationReason.timeout8Min
              : TerminationReason.manualPowerOff,
          status.batteryStatus.level,
        );
        _stopWorkingTimer();
        _elapsedSeconds = 0;
      } else if (status.workingState == WorkingState.pause) {
        // Pause the timer but keep elapsed time
        _pauseWorkingTimer();
      } else if (status.workingState == WorkingState.timeout) {
        // Operation completed - save session with timeout reason
        await _saveAndResetSession(
          TerminationReason.timeout8Min,
          status.batteryStatus.level,
        );
        _stopWorkingTimer();
        // Keep _elapsedSeconds as the final time for display
      }
      emit(DeviceStatusLoaded(status.copyWith(
        currentWorkingTime: _elapsedSeconds,
        totalWorkingTime: totalOperationTime,
      )));
    }
  }

  /// Start tracking a new session
  void _startNewSession(DeviceStatus status) {
    _isSessionActive = true;
    // Calculate actual start time by subtracting elapsed time
    // This handles case where app connects mid-session
    _sessionStartTime = DateTime.now().subtract(Duration(seconds: _elapsedSeconds));
    _sessionShotType = status.shotType;
    _sessionMode = status.mode;
    _sessionLevel = status.level;
    _sessionStartBattery = status.batteryStatus.level;
    _hadTempWarning = false;
    _hadBatteryWarning = false;
  }

  /// Save the current session to local DB and reset tracking
  Future<void> _saveAndResetSession(
    TerminationReason reason,
    int? endBatteryLevel,
  ) async {
    // Only save if we have an active session with meaningful duration
    if (!_isSessionActive ||
        _sessionStartTime == null ||
        _elapsedSeconds < minWorkingDurationSeconds) {
      _resetSessionTracking();
      return;
    }

    try {
      final now = DateTime.now();
      // Use device UUID if available, otherwise generate new one
      final sessionUuid = _sessionUuid ?? const Uuid().v4();
      final session = UsageSession(
        uuid: sessionUuid,
        startTime: _sessionStartTime!,
        endTime: now,
        shotType: _sessionShotType ?? ShotType.unknown,
        mode: _sessionMode ?? DeviceMode.unknown,
        level: _sessionLevel ?? DeviceLevel.level1,
        workingDurationSeconds: _elapsedSeconds,
        pauseDurationSeconds: 0, // App doesn't track pause duration separately
        pauseCount: 0,
        terminationReason: reason,
        completionPercent: (_elapsedSeconds * 100 ~/ totalOperationTime).clamp(0, 100),
        hadTemperatureWarning: _hadTempWarning,
        hadBatteryWarning: _hadBatteryWarning,
        startBatteryLevel: _sessionStartBattery ?? 0,
        endBatteryLevel: endBatteryLevel,
        syncStatus: SyncStatus.notSynced,
        createdAt: now,
        updatedAt: now,
      );

      await usageRepository.startSession(session);
    } catch (e) {
      // Log error but don't crash - session save is best effort
      print('[DeviceStatusBloc] Failed to save local session: $e');
    }

    _resetSessionTracking();
  }

  /// Reset session tracking fields
  void _resetSessionTracking() {
    _isSessionActive = false;
    _sessionStartTime = null;
    _sessionShotType = null;
    _sessionMode = null;
    _sessionLevel = null;
    _sessionStartBattery = null;
    _hadTempWarning = false;
    _hadBatteryWarning = false;
    _sessionUuid = null;
  }

  void _startWorkingTimer() {
    _workingStartTime = DateTime.now().subtract(Duration(seconds: _elapsedSeconds));
    _workingTimer?.cancel();
    _workingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(_TimerTick());
    });
  }

  void _pauseWorkingTimer() {
    _workingTimer?.cancel();
    _workingTimer = null;
  }

  void _stopWorkingTimer() {
    _workingTimer?.cancel();
    _workingTimer = null;
    _workingStartTime = null;
  }

  Future<void> _onTimerTick(
    _TimerTick event,
    Emitter<DeviceStatusState> emit,
  ) async {
    if (_workingStartTime != null) {
      _elapsedSeconds = DateTime.now().difference(_workingStartTime!).inSeconds;

      // Cap at total operation time
      if (_elapsedSeconds > totalOperationTime) {
        _elapsedSeconds = totalOperationTime;
      }

      if (state is DeviceStatusLoaded) {
        final currentStatus = (state as DeviceStatusLoaded).status;
        emit(DeviceStatusLoaded(currentStatus.copyWith(
          currentWorkingTime: _elapsedSeconds,
          totalWorkingTime: totalOperationTime,
        )));
      }
    }
  }

  @override
  Future<void> close() {
    _stopWorkingTimer();
    _timeoutDisplayTimer?.cancel();
    _statusSubscription?.cancel();
    _sessionStartSubscription?.cancel();
    return super.close();
  }
}
