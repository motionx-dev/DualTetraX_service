import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Data Sources
import '../../data/datasources/database_helper.dart';
import '../../data/datasources/usage_local_data_source.dart';
import '../../data/datasources/device_local_data_source.dart';
import '../../data/datasources/ble_remote_data_source.dart';
import '../../data/datasources/ble_ota_data_source.dart';
import '../../data/datasources/local_firmware_data_source.dart';
import '../../data/datasources/ble_comm_data_source.dart';

// Repositories
import '../../data/repositories/device_repository_impl.dart';
import '../../data/repositories/usage_repository_impl.dart';
import '../../data/repositories/ota_repository_impl.dart';
import '../../domain/repositories/device_repository.dart';
import '../../domain/repositories/usage_repository.dart';
import '../../domain/repositories/ota_repository.dart';

// Use Cases
import '../../domain/usecases/connect_to_device.dart';
import '../../domain/usecases/get_device_status.dart';
import '../../domain/usecases/get_daily_statistics.dart';
import '../../domain/usecases/get_weekly_statistics.dart';
import '../../domain/usecases/get_monthly_statistics.dart';
import '../../domain/usecases/get_daily_usage_for_week.dart';
import '../../domain/usecases/get_daily_usage_for_month.dart';
import '../../domain/usecases/delete_all_data.dart';
import '../../domain/usecases/sync_device_sessions.dart';

// Presentation
import '../../presentation/bloc/device_connection/device_connection_bloc.dart';
import '../../presentation/bloc/device_status/device_status_bloc.dart';
import '../../presentation/bloc/usage_statistics/usage_statistics_bloc.dart';
import '../../presentation/bloc/theme/theme_bloc.dart';
import '../../presentation/bloc/locale/locale_bloc.dart';
import '../../presentation/bloc/ota/ota_bloc.dart';
import '../../presentation/bloc/device_sync/device_sync_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Presentation (BLoC)
  sl.registerFactory(
    () => DeviceConnectionBloc(
      connectToDevice: sl(),
      deviceRepository: sl(),
      sharedPreferences: sl(),
    ),
  );

  sl.registerFactory(
    () => DeviceStatusBloc(
      getDeviceStatus: sl(),
      deviceRepository: sl(),
      usageRepository: sl(),
    ),
  );

  sl.registerFactory(
    () => UsageStatisticsBloc(
      getDailyStatistics: sl(),
      getWeeklyStatistics: sl(),
      getMonthlyStatistics: sl(),
      getDailyUsageForWeek: sl(),
      getDailyUsageForMonth: sl(),
      deleteAllData: sl(),
    ),
  );

  sl.registerFactory(
    () => ThemeBloc(sl()),
  );

  sl.registerFactory(
    () => LocaleBloc(sl()),
  );

  sl.registerFactory(
    () => OtaBloc(
      otaRepository: sl(),
      connectionStateStream: sl<DeviceRepository>().connectionStateStream,
    ),
  );

  sl.registerFactory(
    () {
      final bleDataSource = sl<BleRemoteDataSource>() as BleRemoteDataSourceImpl;
      return DeviceSyncBloc(
        syncDeviceSessionsUseCase: sl(),
        bleCommDataSource: sl(),
        connectionStateStream: sl<DeviceRepository>().connectionStateStream,
        getConnectedDevice: () => bleDataSource.connectedDevice,
      );
    },
  );

  //! Use Cases
  sl.registerLazySingleton(() => ConnectToDevice(sl()));
  sl.registerLazySingleton(() => GetDeviceStatus(sl()));
  sl.registerLazySingleton(() => GetDailyStatistics(sl()));
  sl.registerLazySingleton(() => GetWeeklyStatistics(sl()));
  sl.registerLazySingleton(() => GetMonthlyStatistics(sl()));
  sl.registerLazySingleton(() => GetDailyUsageForWeek(sl()));
  sl.registerLazySingleton(() => GetDailyUsageForMonth(sl()));
  sl.registerLazySingleton(() => DeleteAllData(sl()));
  sl.registerLazySingleton(() => SyncDeviceSessionsUseCase(
    usageRepository: sl(),
    bleCommDataSource: sl(),
  ));

  //! Repositories
  sl.registerLazySingleton<DeviceRepository>(
    () {
      final bleDataSource = sl<BleRemoteDataSource>();
      print('[DI] DeviceRepository using BleRemoteDataSource: $bleDataSource');
      return DeviceRepositoryImpl(
        remoteDataSource: bleDataSource,
        localDataSource: sl(),
      );
    },
  );

  sl.registerLazySingleton<UsageRepository>(
    () => UsageRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<OtaRepository>(
    () {
      final bleDataSource = sl<BleRemoteDataSource>() as BleRemoteDataSourceImpl;
      print('[DI] OtaRepository using BleRemoteDataSource hash=${bleDataSource.hashCode}');
      return OtaRepositoryImpl(
        bleOtaDataSource: sl(),
        localFirmwareDataSource: sl(),
        getConnectedDevice: () {
          final device = bleDataSource.connectedDevice;
          print('[DI] getConnectedDevice: hash=${bleDataSource.hashCode}, device: $device');
          return device;
        },
      );
    },
  );

  //! Data Sources
  // Use real BLE for device communication
  sl.registerLazySingleton<BleRemoteDataSource>(
    () {
      final instance = BleRemoteDataSourceImpl();
      print('[DI] BleRemoteDataSource created hash=${instance.hashCode}');
      return instance;
    },
  );

  sl.registerLazySingleton<DeviceLocalDataSource>(
    () => DeviceLocalDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<UsageLocalDataSource>(
    () => UsageLocalDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<BleOtaDataSource>(
    () => BleOtaDataSourceImpl(),
  );

  sl.registerLazySingleton<LocalFirmwareDataSource>(
    () => LocalFirmwareDataSourceImpl(),
  );

  sl.registerLazySingleton<BleCommDataSource>(
    () => BleCommDataSourceImpl(),
  );

  //! Core
  sl.registerLazySingleton(() => DatabaseHelper.instance);

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}
