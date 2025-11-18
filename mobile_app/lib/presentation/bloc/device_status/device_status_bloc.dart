import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/device_status.dart';
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

class DeviceStatusUpdated extends DeviceStatusEvent {
  final DeviceStatus status;

  const DeviceStatusUpdated(this.status);

  @override
  List<Object?> get props => [status];
}

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

// Bloc
class DeviceStatusBloc extends Bloc<DeviceStatusEvent, DeviceStatusState> {
  final GetDeviceStatus getDeviceStatus;
  final DeviceRepository deviceRepository;

  StreamSubscription? _statusSubscription;

  DeviceStatusBloc({
    required this.getDeviceStatus,
    required this.deviceRepository,
  }) : super(DeviceStatusInitial()) {
    on<StartListeningToStatus>(_onStartListening);
    on<DeviceStatusUpdated>(_onStatusUpdated);
  }

  Future<void> _onStartListening(
    StartListeningToStatus event,
    Emitter<DeviceStatusState> emit,
  ) async {
    _statusSubscription = getDeviceStatus(NoParams()).listen((status) {
      add(DeviceStatusUpdated(status));
    });
  }

  Future<void> _onStatusUpdated(
    DeviceStatusUpdated event,
    Emitter<DeviceStatusState> emit,
  ) async {
    emit(DeviceStatusLoaded(event.status));
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    return super.close();
  }
}
