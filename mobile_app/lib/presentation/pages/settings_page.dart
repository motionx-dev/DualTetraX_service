import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/app_localizations.dart';
import '../../core/di/injection_container.dart' as di;
import '../../core/config/demo_mode_service.dart';
import '../../data/datasources/demo_session_generator.dart';
import '../bloc/usage_statistics/usage_statistics_bloc.dart';
import '../bloc/device_connection/device_connection_bloc.dart';
import '../bloc/device_connection/device_connection_event.dart';
import '../bloc/device_connection/device_connection_state.dart';
import '../bloc/theme/theme_bloc.dart';
import '../bloc/locale/locale_bloc.dart';
import '../bloc/ota/ota_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/cloud_sync/cloud_sync_bloc.dart';
import '../bloc/cloud_sync/cloud_sync_event.dart';
import '../bloc/cloud_sync/cloud_sync_state.dart';
import '../bloc/profile/profile_bloc.dart';
import 'ota_page.dart';
import 'profile/profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _versionTapCount = 0;
  DateTime? _lastTapTime;
  late bool _isDeveloperMode;
  late bool _isDemoModeEnabled;

  @override
  void initState() {
    super.initState();
    final demoService = di.sl<DemoModeService>();
    _isDeveloperMode = demoService.isDeveloperOptionsEnabled;
    _isDemoModeEnabled = demoService.isEnabled;
  }

  void _onVersionTap() {
    if (!kDebugMode) return;

    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds > 3) {
      _versionTapCount = 0;
    }
    _lastTapTime = now;
    _versionTapCount++;

    if (_versionTapCount >= 7) {
      _versionTapCount = 0;
      if (!_isDeveloperMode) {
        setState(() => _isDeveloperMode = true);
        di.sl<DemoModeService>().setDeveloperOptionsEnabled(true);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.developerOptionsEnabled)),
        );
      }
    }
  }

  Future<void> _onDemoModeToggle(bool value) async {
    final l10n = AppLocalizations.of(context)!;
    await di.sl<DemoModeService>().setEnabled(value);
    setState(() => _isDemoModeEnabled = value);

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.restartRequired),
        content: Text(l10n.restartRequiredMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.later),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.restartNow),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      SystemNavigator.pop();
    }
  }

  Future<void> _onGenerateDemoData() async {
    final l10n = AppLocalizations.of(context)!;
    final generator = di.sl<DemoSessionGenerator>();
    final count = await generator.generateDemoData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.demoDataGenerated(count))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          _SectionHeader(title: l10n.account),
          ListTile(
            leading: Icon(
              Icons.person_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(l10n.profile),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => di.sl<ProfileBloc>(),
                    child: const ProfilePage(),
                  ),
                ),
              );
            },
          ),
          BlocBuilder<CloudSyncBloc, CloudSyncState>(
            builder: (context, state) {
              String? subtitle;
              if (state is CloudSyncing) {
                subtitle = '...';
              } else if (state is CloudSyncSuccess) {
                subtitle = '${state.uploaded} uploaded';
              } else if (state is CloudSyncError) {
                subtitle = state.message;
              } else if (state is CloudSyncNoData) {
                subtitle = 'Up to date';
              }
              return ListTile(
                leading: Icon(
                  Icons.cloud_sync_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(l10n.cloudSync),
                subtitle: subtitle != null ? Text(subtitle) : null,
                trailing: state is CloudSyncing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.chevron_right),
                onTap: state is CloudSyncing
                    ? null
                    : () {
                        context.read<CloudSyncBloc>().add(const SyncToServerRequested());
                      },
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l10n.logout,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _showLogoutConfirmation(context),
          ),
          const Divider(),
          _SectionHeader(title: l10n.appearance),
          _ThemeSelectorTile(),
          _LanguageSelectorTile(),
          const Divider(),
          _SectionHeader(title: l10n.device),
          ListTile(
            leading: Icon(
              Icons.bluetooth,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(l10n.connectedDevice),
            subtitle: const Text('DualTetraX'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show device details
            },
          ),
          _AutoReconnectTile(),
          ListTile(
            leading: Icon(
              Icons.system_update,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(l10n.firmwareUpdate),
            subtitle: Text(l10n.firmwareUpdateSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final connectionState = context.read<DeviceConnectionBloc>().state;

              if (connectionState is! DeviceConnected) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.deviceNotConnected)),
                );
                return;
              }

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => di.sl<OtaBloc>(),
                    child: const OtaPage(),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.bluetooth_disabled,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(l10n.disconnectDevice),
            onTap: () {
              context.read<DeviceConnectionBloc>().add(DisconnectRequested());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.disconnected)),
              );
            },
          ),
          const Divider(),
          _SectionHeader(title: l10n.data),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l10n.deleteAllData,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _showDeleteConfirmation(context),
          ),
          const Divider(),
          _SectionHeader(title: l10n.information),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.appVersion),
            trailing: const Text('1.0.0'),
            onTap: _onVersionTap,
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: Text(l10n.termsOfService),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show terms of service
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: Text(l10n.privacyPolicy),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show privacy policy
            },
          ),
          // Developer Options (debug builds only, after 7-tap activation)
          if (kDebugMode && _isDeveloperMode) ...[
            const Divider(),
            _SectionHeader(title: l10n.developer),
            SwitchListTile(
              secondary: Icon(
                Icons.developer_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(l10n.deviceSimulator),
              subtitle: Text(l10n.deviceSimulatorSubtitle),
              value: _isDemoModeEnabled,
              onChanged: _onDemoModeToggle,
            ),
            ListTile(
              leading: Icon(
                Icons.auto_fix_high,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(l10n.generateDemoData),
              subtitle: Text(l10n.generateDemoDataSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: _onGenerateDemoData,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(const LogoutRequested());
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteDataTitle),
        content: Text(l10n.deleteDataMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<UsageStatisticsBloc>().add(DeleteAllDataRequested());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.allDataDeleted)),
        );
      }
    }
  }
}

class _ThemeSelectorTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return ListTile(
          leading: Icon(
            Icons.palette_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(l10n.theme),
          subtitle: Text(_getThemeModeText(context, state.themeMode)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showThemeDialog(context, state.themeMode),
        );
      },
    );
  }

  String _getThemeModeText(BuildContext context, ThemeMode mode) {
    final l10n = AppLocalizations.of(context)!;

    switch (mode) {
      case ThemeMode.light:
        return l10n.lightMode;
      case ThemeMode.dark:
        return l10n.darkMode;
      case ThemeMode.system:
        return l10n.systemMode;
    }
  }

  Future<void> _showThemeDialog(BuildContext context, ThemeMode currentMode) async {
    final l10n = AppLocalizations.of(context)!;

    final selectedMode = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectTheme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeOptionTile(
              title: l10n.lightMode,
              icon: Icons.light_mode,
              mode: ThemeMode.light,
              currentMode: currentMode,
            ),
            _ThemeOptionTile(
              title: l10n.darkMode,
              icon: Icons.dark_mode,
              mode: ThemeMode.dark,
              currentMode: currentMode,
            ),
            _ThemeOptionTile(
              title: l10n.systemMode,
              icon: Icons.settings_suggest,
              mode: ThemeMode.system,
              currentMode: currentMode,
            ),
          ],
        ),
      ),
    );

    if (selectedMode != null && context.mounted) {
      context.read<ThemeBloc>().add(ChangeTheme(selectedMode));
    }
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final ThemeMode mode;
  final ThemeMode currentMode;

  const _ThemeOptionTile({
    required this.title,
    required this.icon,
    required this.mode,
    required this.currentMode,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == currentMode;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () => Navigator.pop(context, mode),
    );
  }
}

class _LanguageSelectorTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<LocaleBloc, LocaleState>(
      builder: (context, state) {
        return ListTile(
          leading: Icon(
            Icons.language,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(l10n.language),
          subtitle: Text(_getLanguageName(context, state.locale)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showLanguageDialog(context, state.locale),
        );
      },
    );
  }

  String _getLanguageName(BuildContext context, Locale? locale) {
    final l10n = AppLocalizations.of(context)!;

    if (locale == null) return l10n.systemMode;
    switch (locale.languageCode) {
      case 'ko':
        return l10n.korean;
      case 'en':
        return l10n.english;
      case 'zh':
        return l10n.chinese;
      case 'ja':
        return l10n.japanese;
      case 'pt':
        return l10n.portuguese;
      case 'es':
        return l10n.spanish;
      case 'vi':
        return l10n.vietnamese;
      case 'th':
        return l10n.thai;
      default:
        return l10n.systemMode;
    }
  }

  Future<void> _showLanguageDialog(BuildContext context, Locale? currentLocale) async {
    final l10n = AppLocalizations.of(context)!;

    final selectedLocale = await showDialog<Locale?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LanguageOptionTile(
                title: l10n.systemMode,
                locale: null,
                currentLocale: currentLocale,
              ),
              const Divider(),
              _LanguageOptionTile(
                title: l10n.korean,
                locale: const Locale('ko'),
                currentLocale: currentLocale,
              ),
              _LanguageOptionTile(
                title: l10n.english,
                locale: const Locale('en'),
                currentLocale: currentLocale,
              ),
              _LanguageOptionTile(
                title: l10n.chinese,
                locale: const Locale('zh'),
                currentLocale: currentLocale,
              ),
              _LanguageOptionTile(
                title: l10n.japanese,
                locale: const Locale('ja'),
                currentLocale: currentLocale,
              ),
              _LanguageOptionTile(
                title: l10n.portuguese,
                locale: const Locale('pt'),
                currentLocale: currentLocale,
              ),
              _LanguageOptionTile(
                title: l10n.spanish,
                locale: const Locale('es'),
                currentLocale: currentLocale,
              ),
              _LanguageOptionTile(
                title: l10n.vietnamese,
                locale: const Locale('vi'),
                currentLocale: currentLocale,
              ),
              _LanguageOptionTile(
                title: l10n.thai,
                locale: const Locale('th'),
                currentLocale: currentLocale,
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedLocale != null && context.mounted) {
      context.read<LocaleBloc>().add(ChangeLocale(selectedLocale));
    }
  }
}

class _LanguageOptionTile extends StatelessWidget {
  final String title;
  final Locale? locale;
  final Locale? currentLocale;

  const _LanguageOptionTile({
    required this.title,
    required this.locale,
    required this.currentLocale,
  });

  @override
  Widget build(BuildContext context) {
    final localeCode = locale?.languageCode;
    final currentLocaleCode = currentLocale?.languageCode;

    bool isSelected = false;
    if (localeCode == null && currentLocaleCode == null) {
      isSelected = true;
    } else if (localeCode != null && currentLocaleCode != null) {
      isSelected = localeCode == currentLocaleCode;
    }

    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () => Navigator.pop(context, locale),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _AutoReconnectTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<DeviceConnectionBloc>();

    return Column(
      children: [
        SwitchListTile(
          secondary: Icon(
            Icons.autorenew,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(l10n.autoReconnect),
          value: bloc.isAutoReconnectEnabled,
          onChanged: (value) {
            bloc.add(AutoReconnectSettingsChanged(enabled: value));
          },
        ),
        if (bloc.isAutoReconnectEnabled)
          ListTile(
            leading: const SizedBox(width: 24),
            title: Text(l10n.autoReconnectInterval),
            subtitle: Text('${bloc.autoReconnectInterval} ${l10n.seconds}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showIntervalDialog(context, bloc.autoReconnectInterval),
          ),
      ],
    );
  }

  Future<void> _showIntervalDialog(BuildContext context, int currentInterval) async {
    final l10n = AppLocalizations.of(context)!;

    final intervals = [30, 60, 120, 180, 300];

    final selectedInterval = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.autoReconnectInterval),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals.map((interval) {
            final isSelected = interval == currentInterval;
            return ListTile(
              title: Text(
                '$interval ${l10n.seconds}',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () => Navigator.pop(context, interval),
            );
          }).toList(),
        ),
      ),
    );

    if (selectedInterval != null && context.mounted) {
      context.read<DeviceConnectionBloc>().add(
        AutoReconnectSettingsChanged(intervalSeconds: selectedInterval),
      );
    }
  }
}
