import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/app_localizations.dart';
import '../bloc/device_connection/device_connection_bloc.dart';
import '../bloc/device_connection/device_connection_state.dart';
import '../bloc/device_status/device_status_bloc.dart';

class ConnectionStatusWidget extends StatelessWidget {
  const ConnectionStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<DeviceConnectionBloc, DeviceConnectionState>(
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildStatusIcon(state),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusTitle(context, state),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getStatusMessage(context, state),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (state is DeviceConnected) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  BlocBuilder<DeviceStatusBloc, DeviceStatusState>(
                    builder: (context, statusState) {
                      if (statusState is DeviceStatusLoaded) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusRow(
                              l10n.shotType,
                              statusState.status.shotType.displayName,
                            ),
                            _buildStatusRow(
                              l10n.mode,
                              statusState.status.mode.displayName,
                            ),
                            _buildStatusRow(
                              l10n.level,
                              statusState.status.level.displayName,
                            ),
                            _buildStatusRow(
                              l10n.battery,
                              '${statusState.status.batteryStatus.level}%',
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(DeviceConnectionState state) {
    if (state is DeviceConnected) {
      return const Icon(Icons.bluetooth_connected, color: Colors.green, size: 32);
    } else if (state is DeviceConnecting) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(strokeWidth: 3),
      );
    } else {
      return const Icon(Icons.bluetooth_disabled, color: Colors.grey, size: 32);
    }
  }

  String _getStatusTitle(BuildContext context, DeviceConnectionState state) {
    final l10n = AppLocalizations.of(context)!;

    if (state is DeviceConnected) {
      return l10n.connected;
    } else if (state is DeviceConnecting) {
      return l10n.connecting;
    } else if (state is DeviceConnectionError) {
      return l10n.connectionFailed('');
    } else {
      return l10n.disconnected;
    }
  }

  String _getStatusMessage(BuildContext context, DeviceConnectionState state) {
    final l10n = AppLocalizations.of(context)!;

    if (state is DeviceConnected) {
      return l10n.connectedToDevice;
    } else if (state is DeviceConnecting) {
      return l10n.searchingDevice;
    } else if (state is DeviceConnectionError) {
      return state.message;
    } else {
      return l10n.tapToConnect;
    }
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
