import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/usecases/connect_to_device.dart';
import '../../../domain/repositories/device_repository.dart';
import '../../../domain/entities/connection_state.dart';
import '../../../domain/entities/working_state.dart';
import '../../../core/usecases/usecase.dart';
import 'device_connection_event.dart';
import 'device_connection_state.dart';

class DeviceConnectionBloc
    extends Bloc<DeviceConnectionEvent, DeviceConnectionState> {
  final ConnectToDevice connectToDevice;
  final DeviceRepository deviceRepository;
  final SharedPreferences sharedPreferences;

  StreamSubscription? _connectionStateSubscription;
  Timer? _autoReconnectTimer;
  bool _wasConnected = false;

  static const String _keyAutoReconnectEnabled = 'auto_reconnect_enabled';
  static const String _keyAutoReconnectInterval = 'auto_reconnect_interval';
  static const int _defaultReconnectInterval = 60;

  DeviceConnectionBloc({
    required this.connectToDevice,
    required this.deviceRepository,
    required this.sharedPreferences,
  }) : super(DeviceConnectionInitial()) {
    on<ConnectRequested>(_onConnectRequested);
    on<DisconnectRequested>(_onDisconnectRequested);
    on<ConnectionStateChanged>(_onConnectionStateChanged);
    on<AutoReconnectSettingsChanged>(_onAutoReconnectSettingsChanged);

    _listenToConnectionState();
  }

  bool get isAutoReconnectEnabled =>
      sharedPreferences.getBool(_keyAutoReconnectEnabled) ?? true;

  int get autoReconnectInterval =>
      sharedPreferences.getInt(_keyAutoReconnectInterval) ?? _defaultReconnectInterval;

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
    _wasConnected = false;
    _stopAutoReconnect();
    await deviceRepository.disconnect();
    emit(const DeviceDisconnected());
  }

  Future<void> _onConnectionStateChanged(
    ConnectionStateChanged event,
    Emitter<DeviceConnectionState> emit,
  ) async {
    if (event.isConnected) {
      _wasConnected = true;
      _stopAutoReconnect();
      emit(DeviceConnected());
    } else {
      emit(const DeviceDisconnected());
      // Skip auto-reconnect if device is in OTA mode
      final lastState = deviceRepository.lastWorkingState;
      if (_wasConnected && isAutoReconnectEnabled && lastState != WorkingState.ota) {
        _startAutoReconnect();
      }
    }
  }

  Future<void> _onAutoReconnectSettingsChanged(
    AutoReconnectSettingsChanged event,
    Emitter<DeviceConnectionState> emit,
  ) async {
    if (event.enabled != null) {
      await sharedPreferences.setBool(_keyAutoReconnectEnabled, event.enabled!);
      if (!event.enabled!) {
        _stopAutoReconnect();
      }
    }
    if (event.intervalSeconds != null) {
      await sharedPreferences.setInt(_keyAutoReconnectInterval, event.intervalSeconds!);
      if (_autoReconnectTimer != null && isAutoReconnectEnabled) {
        _stopAutoReconnect();
        _startAutoReconnect();
      }
    }
  }

  void _startAutoReconnect() {
    _stopAutoReconnect();
    final interval = Duration(seconds: autoReconnectInterval);
    _autoReconnectTimer = Timer.periodic(interval, (_) {
      if (state is! DeviceConnecting && state is! DeviceConnected) {
        add(ConnectRequested());
      }
    });
  }

  void _stopAutoReconnect() {
    _autoReconnectTimer?.cancel();
    _autoReconnectTimer = null;
  }

  @override
  Future<void> close() {
    _connectionStateSubscription?.cancel();
    _stopAutoReconnect();
    return super.close();
  }
}
