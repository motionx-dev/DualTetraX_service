import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/devices/register_server_device.dart' as register_usecase;
import '../../../domain/usecases/devices/get_server_devices.dart';
import 'server_device_event.dart';
import 'server_device_state.dart';

class ServerDeviceBloc extends Bloc<ServerDeviceEvent, ServerDeviceState> {
  final register_usecase.RegisterServerDevice registerServerDevice;
  final GetServerDevices getServerDevices;
  final SharedPreferences sharedPreferences;

  static const String _serverDeviceIdKey = 'server_device_id';

  ServerDeviceBloc({
    required this.registerServerDevice,
    required this.getServerDevices,
    required this.sharedPreferences,
  }) : super(const ServerDeviceInitial()) {
    on<LoadServerDevices>(_onLoadDevices);
    on<RegisterServerDevice>(_onRegisterDevice);
  }

  Future<void> _onLoadDevices(LoadServerDevices event, Emitter<ServerDeviceState> emit) async {
    emit(const ServerDeviceLoading());
    final result = await getServerDevices(NoParams());
    result.fold(
      (failure) => emit(ServerDeviceError(failure.message)),
      (devices) => emit(ServerDevicesLoaded(devices)),
    );
  }

  Future<void> _onRegisterDevice(RegisterServerDevice event, Emitter<ServerDeviceState> emit) async {
    emit(const ServerDeviceLoading());
    final result = await registerServerDevice(
      register_usecase.RegisterDeviceParams(
        serialNumber: event.serialNumber,
        modelName: event.modelName,
        firmwareVersion: event.firmwareVersion,
        bleMacAddress: event.bleMacAddress,
      ),
    );
    result.fold(
      (failure) {
        // If conflict (409), device already registered - try to get devices to find it
        if (failure.message.contains('already registered') || failure.message.contains('conflict')) {
          add(const LoadServerDevices());
        } else {
          emit(ServerDeviceError(failure.message));
        }
      },
      (device) {
        // Store server device ID for session sync
        sharedPreferences.setString(_serverDeviceIdKey, device.id);
        emit(ServerDeviceRegistered(device));
      },
    );
  }
}
