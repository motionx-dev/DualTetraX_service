import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core - Config
import '../../core/config/demo_mode_service.dart';

// Data Sources - Local/BLE
import '../../data/datasources/database_helper.dart';
import '../../data/datasources/usage_local_data_source.dart';
import '../../data/datasources/device_local_data_source.dart';
import '../../data/datasources/ble_remote_data_source.dart';
import '../../data/datasources/ble_mock_data_source.dart';
import '../../data/datasources/ble_ota_data_source.dart';
import '../../data/datasources/local_firmware_data_source.dart';
import '../../data/datasources/ble_comm_data_source.dart';
import '../../data/datasources/demo_session_generator.dart';

// Data Sources - Server
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/device_remote_data_source.dart';
import '../../data/datasources/session_remote_data_source.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/datasources/goal_remote_data_source.dart';
import '../../data/datasources/stats_remote_data_source.dart';
import '../../data/datasources/firmware_remote_data_source.dart';

// Repositories - Local/BLE
import '../../data/repositories/device_repository_impl.dart';
import '../../data/repositories/usage_repository_impl.dart';
import '../../data/repositories/ota_repository_impl.dart';
import '../../domain/repositories/device_repository.dart';
import '../../domain/repositories/usage_repository.dart';
import '../../domain/repositories/ota_repository.dart';

// Repositories - Server
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/server_device_repository_impl.dart';
import '../../data/repositories/session_sync_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/repositories/goal_repository_impl.dart';
import '../../data/repositories/server_stats_repository_impl.dart';
import '../../data/repositories/server_firmware_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/server_device_repository.dart';
import '../../domain/repositories/session_sync_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/repositories/server_stats_repository.dart';
import '../../domain/repositories/server_firmware_repository.dart';

// Use Cases - Local
import '../../domain/usecases/connect_to_device.dart';
import '../../domain/usecases/get_device_status.dart';
import '../../domain/usecases/get_daily_statistics.dart';
import '../../domain/usecases/get_weekly_statistics.dart';
import '../../domain/usecases/get_monthly_statistics.dart';
import '../../domain/usecases/get_daily_usage_for_week.dart';
import '../../domain/usecases/get_daily_usage_for_month.dart';
import '../../domain/usecases/delete_all_data.dart';
import '../../domain/usecases/sync_device_sessions.dart';

// Use Cases - Server
import '../../domain/usecases/auth/login_with_email.dart';
import '../../domain/usecases/auth/signup_with_email.dart';
import '../../domain/usecases/auth/logout.dart';
import '../../domain/usecases/auth/auto_login.dart';
import '../../domain/usecases/auth/login_with_google.dart';
import '../../domain/usecases/auth/login_with_apple.dart';
import '../../domain/usecases/devices/register_server_device.dart';
import '../../domain/usecases/devices/get_server_devices.dart';
import '../../domain/usecases/sync/upload_sessions_to_server.dart';
import '../../domain/usecases/profile/get_profile.dart';
import '../../domain/usecases/profile/update_profile.dart';
import '../../domain/usecases/goals/get_goals.dart';
import '../../domain/usecases/goals/create_goal.dart';
import '../../domain/usecases/goals/update_goal.dart';
import '../../domain/usecases/goals/delete_goal.dart';
import '../../domain/usecases/firmware/check_firmware_update.dart';

// Core - Network
import '../../core/network/api_client.dart';
import '../../core/network/network_info.dart';

// Presentation - Local
import '../../presentation/bloc/device_connection/device_connection_bloc.dart';
import '../../presentation/bloc/device_status/device_status_bloc.dart';
import '../../presentation/bloc/usage_statistics/usage_statistics_bloc.dart';
import '../../presentation/bloc/theme/theme_bloc.dart';
import '../../presentation/bloc/locale/locale_bloc.dart';
import '../../presentation/bloc/ota/ota_bloc.dart';
import '../../presentation/bloc/device_sync/device_sync_bloc.dart';

// Presentation - Server
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/bloc/cloud_sync/cloud_sync_bloc.dart';
import '../../presentation/bloc/server_device/server_device_bloc.dart';
import '../../presentation/bloc/profile/profile_bloc.dart';
import '../../presentation/bloc/goal/goal_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! External (must be first - other registrations depend on these)
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  //! Core
  sl.registerLazySingleton(() => DatabaseHelper.instance);
  sl.registerLazySingleton(() => ApiClient());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(Connectivity()));
  sl.registerLazySingleton(() => DemoModeService(sharedPreferences));

  final isDemoMode = sl<DemoModeService>().isEnabled;

  //! Data Sources - Local
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

  //! Data Sources - BLE (conditional on demo mode)
  if (isDemoMode) {
    final mockDataSource = BleMockDataSource(usageLocalDataSource: sl());
    sl.registerLazySingleton<BleRemoteDataSource>(() => mockDataSource);
    sl.registerLazySingleton<BleCommDataSource>(() => mockDataSource);
  } else {
    sl.registerLazySingleton<BleRemoteDataSource>(
      () => BleRemoteDataSourceImpl(),
    );
    sl.registerLazySingleton<BleCommDataSource>(
      () => BleCommDataSourceImpl(),
    );
  }

  //! Data Sources - Server
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<DeviceRemoteDataSource>(
    () => DeviceRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<SessionRemoteDataSource>(
    () => SessionRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<GoalRemoteDataSource>(
    () => GoalRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<StatsRemoteDataSource>(
    () => StatsRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<FirmwareRemoteDataSource>(
    () => FirmwareRemoteDataSourceImpl(apiClient: sl()),
  );

  //! Demo Session Generator
  sl.registerLazySingleton(() => DemoSessionGenerator(sl()));

  //! Repositories - Local
  sl.registerLazySingleton<DeviceRepository>(
    () => DeviceRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  sl.registerLazySingleton<UsageRepository>(
    () => UsageRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<OtaRepository>(
    () {
      final bleDataSource = sl<BleRemoteDataSource>();
      return OtaRepositoryImpl(
        bleOtaDataSource: sl(),
        localFirmwareDataSource: sl(),
        getConnectedDevice: () {
          if (bleDataSource is BleRemoteDataSourceImpl) {
            return bleDataSource.connectedDevice;
          }
          // Mock mode: create a dummy BluetoothDevice
          return BluetoothDevice.fromId('00:11:22:33:44:55');
        },
      );
    },
  );

  //! Repositories - Server
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<ServerDeviceRepository>(
    () => ServerDeviceRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<SessionSyncRepository>(
    () => SessionSyncRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<GoalRepository>(
    () => GoalRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<ServerStatsRepository>(
    () => ServerStatsRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<ServerFirmwareRepository>(
    () => ServerFirmwareRepositoryImpl(remoteDataSource: sl()),
  );

  //! Use Cases - Local
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

  //! Use Cases - Server
  sl.registerLazySingleton(() => LoginWithEmail(sl()));
  sl.registerLazySingleton(() => SignupWithEmail(sl()));
  sl.registerLazySingleton(() => Logout(sl()));
  sl.registerLazySingleton(() => AutoLogin(sl()));
  sl.registerLazySingleton(() => LoginWithGoogle(sl()));
  sl.registerLazySingleton(() => LoginWithApple(sl()));
  sl.registerLazySingleton(() => RegisterServerDevice(sl()));
  sl.registerLazySingleton(() => GetServerDevices(sl()));
  sl.registerLazySingleton(() => UploadSessionsToServer(
    sessionSyncRepository: sl(),
    usageRepository: sl(),
    usageLocalDataSource: sl(),
  ));
  sl.registerLazySingleton(() => GetProfile(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));
  sl.registerLazySingleton(() => GetGoals(sl()));
  sl.registerLazySingleton(() => CreateGoal(sl()));
  sl.registerLazySingleton(() => UpdateGoal(sl()));
  sl.registerLazySingleton(() => DeleteGoal(sl()));
  sl.registerLazySingleton(() => CheckFirmwareUpdate(sl()));

  //! Features - Presentation (BLoC) - Local
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
      bleCommDataSource: sl(),
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
      final bleDataSource = sl<BleRemoteDataSource>();
      return DeviceSyncBloc(
        syncDeviceSessionsUseCase: sl(),
        bleCommDataSource: sl(),
        connectionStateStream: sl<DeviceRepository>().connectionStateStream,
        getConnectedDevice: () {
          if (bleDataSource is BleRemoteDataSourceImpl) {
            return bleDataSource.connectedDevice;
          }
          // Mock mode: return a dummy BluetoothDevice for DeviceSyncBloc
          return BluetoothDevice.fromId('00:11:22:33:44:55');
        },
      );
    },
  );

  //! Features - Presentation (BLoC) - Server
  sl.registerFactory(
    () => AuthBloc(
      loginWithEmail: sl(),
      signupWithEmail: sl(),
      logout: sl(),
      autoLogin: sl(),
      loginWithGoogle: sl(),
      loginWithApple: sl(),
      authRepository: sl(),
    ),
  );

  sl.registerFactory(
    () => CloudSyncBloc(
      uploadSessionsToServer: sl(),
      sharedPreferences: sl(),
    ),
  );

  sl.registerFactory(
    () => ServerDeviceBloc(
      registerServerDevice: sl(),
      getServerDevices: sl(),
      sharedPreferences: sl(),
    ),
  );

  sl.registerFactory(
    () => ProfileBloc(
      getProfile: sl(),
      updateProfileUseCase: sl(),
      profileRepository: sl(),
    ),
  );

  sl.registerFactory(
    () => GoalBloc(
      getGoals: sl(),
      createGoalUseCase: sl(),
      updateGoalUseCase: sl(),
      deleteGoalUseCase: sl(),
    ),
  );
}
