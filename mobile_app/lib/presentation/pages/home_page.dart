import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/app_localizations.dart';
import '../bloc/device_connection/device_connection_bloc.dart';
import '../bloc/device_connection/device_connection_event.dart';
import '../bloc/device_connection/device_connection_state.dart';
import '../bloc/device_status/device_status_bloc.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/today_usage_widget.dart';
import 'statistics_page.dart';
import 'guide_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Start listening to device status
    context.read<DeviceStatusBloc>().add(StartListeningToStatus());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DualTetraX'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection Status
              const ConnectionStatusWidget(),
              const SizedBox(height: 24),

              // Connect Button
              BlocBuilder<DeviceConnectionBloc, DeviceConnectionState>(
                builder: (context, state) {
                  final l10n = AppLocalizations.of(context)!;

                  if (state is DeviceDisconnected ||
                      state is DeviceConnectionInitial) {
                    return ElevatedButton.icon(
                      icon: const Icon(Icons.bluetooth),
                      label: Text(l10n.connectDevice),
                      onPressed: () {
                        context.read<DeviceConnectionBloc>()
                            .add(ConnectRequested());
                      },
                    );
                  } else if (state is DeviceConnecting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is DeviceConnectionError) {
                    return Column(
                      children: [
                        Text(
                          l10n.connectionFailed(state.message),
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            context.read<DeviceConnectionBloc>()
                                .add(ConnectRequested());
                          },
                          child: Text(l10n.retry),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 24),

              // Today's Usage
              const TodayUsageWidget(),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.quickMenu,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.bar_chart,
                title: l10n.usageHistory,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StatisticsPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.book,
                title: l10n.usageGuide,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GuidePage()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 48, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
