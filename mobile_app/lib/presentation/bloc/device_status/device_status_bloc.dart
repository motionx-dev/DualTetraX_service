import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/device_status.dart';
import '../../../domain/entities/working_state.dart';
import '../../../domain/usecases/get_device_status.dart';
import '../../../domain/repositories/device_repository.dart';
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

  StreamSubscription? _statusSubscription;
  Timer? _workingTimer;
  Timer? _timeoutDisplayTimer;
  DateTime? _workingStartTime;
  int _elapsedSeconds = 0;
  DeviceStatus? _lastStatus;

  // Total operation time: 8 minutes = 480 seconds
  static const int totalOperationTime = 480;
  static const int timeoutDisplayDuration = 15;

  DeviceStatusBloc({
    required this.getDeviceStatus,
    required this.deviceRepository,
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
  }

  Future<void> _onStopListening(
    StopListeningToStatus event,
    Emitter<DeviceStatusState> emit,
  ) async {
    _stopWorkingTimer();
    _statusSubscription?.cancel();
    _statusSubscription = null;

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

    // Handle working state changes for time tracking
    if (status.workingState == WorkingState.working) {
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
        _stopWorkingTimer();
        _elapsedSeconds = 0;
      } else if (status.workingState == WorkingState.pause) {
        // Pause the timer but keep elapsed time
        _pauseWorkingTimer();
      } else if (status.workingState == WorkingState.timeout) {
        // Operation completed - stop timer but keep final elapsed time
        _stopWorkingTimer();
        // Keep _elapsedSeconds as the final time (should equal totalOperationTime)
      }
      emit(DeviceStatusLoaded(status.copyWith(
        currentWorkingTime: _elapsedSeconds,
        totalWorkingTime: totalOperationTime,
      )));
    }
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
    return super.close();
  }
}
