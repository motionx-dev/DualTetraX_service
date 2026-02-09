import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'l10n/app_localizations.dart';
import 'core/config/app_config.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';
import 'presentation/bloc/auth/auth_state.dart';
import 'presentation/bloc/device_connection/device_connection_bloc.dart';
import 'presentation/bloc/device_status/device_status_bloc.dart';
import 'presentation/bloc/usage_statistics/usage_statistics_bloc.dart';
import 'presentation/bloc/theme/theme_bloc.dart';
import 'presentation/bloc/locale/locale_bloc.dart';
import 'presentation/bloc/device_sync/device_sync_bloc.dart';
import 'presentation/bloc/cloud_sync/cloud_sync_bloc.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/auth/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable flutter_blue_plus verbose logs (native iOS/Android logs)
  FlutterBluePlus.setLogLevel(LogLevel.none);

  // Lock orientation to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // Initialize dependencies
  await di.init();

  runApp(const DualTetraXApp());
}

class DualTetraXApp extends StatelessWidget {
  const DualTetraXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(
          create: (_) => di.sl<ThemeBloc>()..add(LoadTheme()),
        ),
        BlocProvider<LocaleBloc>(
          create: (_) => di.sl<LocaleBloc>()..add(LoadLocale()),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>()..add(const AutoLoginRequested()),
        ),
        BlocProvider<DeviceConnectionBloc>(
          create: (_) => di.sl<DeviceConnectionBloc>(),
        ),
        BlocProvider<DeviceStatusBloc>(
          create: (_) => di.sl<DeviceStatusBloc>(),
        ),
        BlocProvider<UsageStatisticsBloc>(
          create: (_) => di.sl<UsageStatisticsBloc>(),
        ),
        BlocProvider<DeviceSyncBloc>(
          create: (_) => di.sl<DeviceSyncBloc>(),
        ),
        BlocProvider<CloudSyncBloc>(
          create: (_) => di.sl<CloudSyncBloc>(),
        ),
      ],
      child: BlocBuilder<LocaleBloc, LocaleState>(
        builder: (context, localeState) {
          return BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              return MaterialApp(
            title: 'DualTetraX',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeState.themeMode,
            locale: localeState.locale,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('ko'), // Korean
              Locale('zh'), // Chinese
              Locale('ja'), // Japanese
              Locale('pt'), // Portuguese
              Locale('es'), // Spanish
              Locale('vi'), // Vietnamese
              Locale('th'), // Thai
            ],
            home: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                if (authState is AuthInitial || authState is AuthLoading) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (authState is Authenticated) {
                  return const HomePage();
                }
                return const LoginPage();
              },
            ),
            debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }
}
