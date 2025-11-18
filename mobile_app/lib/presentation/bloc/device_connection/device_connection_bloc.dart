import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/connect_to_device.dart';
import '../../../domain/repositories/device_repository.dart';
import '../../../domain/entities/connection_state.dart';
import '../../../core/usecases/usecase.dart';
import 'device_connection_event.dart';
import 'device_connection_state.dart';

class DeviceConnectionBloc
    extends Bloc<DeviceConnectionEvent, DeviceConnectionState> {
  final ConnectToDevice connectToDevice;
  final DeviceRepository deviceRepository;

  StreamSubscription? _connectionStateSubscription;

  DeviceConnectionBloc({
    required this.connectToDevice,
    required this.deviceRepository,
  }) : super(DeviceConnectionInitial()) {
    on<ConnectRequested>(_onConnectRequested);
    on<DisconnectRequested>(_onDisconnectRequested);
    on<ConnectionStateChanged>(_onConnectionStateChanged);

    _listenToConnectionState();
  }

  void _listenToConnectionState() {
    _connectionStateSubscription =
        deviceRepository.connectionStateStream.listen((connectionState) {
      if (connectionState == BleConnectionState.connected) {
        add(const ConnectionStateChanged(true));
      } else if (connectionState == BleConnectionState.disconnected) {
        add(const ConnectionStateChanged(false));
      }
    });
  }

  Future<void> _onConnectRequested(
    ConnectRequested event,
    Emitter<DeviceConnectionState> emit,
  ) async {
    emit(DeviceConnecting());

    final result = await connectToDevice(NoParams());

    result.fold(
      (failure) => emit(DeviceConnectionError(failure.message)),
      (_) => emit(DeviceConnected()),
    );
  }

  Future<void> _onDisconnectRequested(
    DisconnectRequested event,
    Emitter<DeviceConnectionState> emit,
  ) async {
    await deviceRepository.disconnect();
    emit(const DeviceDisconnected());
  }

  Future<void> _onConnectionStateChanged(
    ConnectionStateChanged event,
    Emitter<DeviceConnectionState> emit,
  ) async {
    if (event.isConnected) {
      emit(DeviceConnected());
    } else {
      emit(const DeviceDisconnected());
    }
  }

  @override
  Future<void> close() {
    _connectionStateSubscription?.cancel();
    return super.close();
  }
}
