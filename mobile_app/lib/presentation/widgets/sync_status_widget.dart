import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/device_sync/device_sync_bloc.dart';
import '../bloc/device_sync/device_sync_event.dart';
import '../bloc/device_sync/device_sync_state.dart';

class SyncStatusWidget extends StatelessWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceSyncBloc, DeviceSyncState>(
      builder: (context, state) {
        if (state is DeviceSyncInitial) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
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
                            _getStatusTitle(state),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getStatusMessage(state),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state is DeviceSyncTimeSynced) ...[
                      TextButton(
                        onPressed: () {
                          context.read<DeviceSyncBloc>().add(const SessionSyncRequested());
                        },
                        child: const Text('Sync Sessions'),
                      ),
                    ],
                  ],
                ),
                if (state is DeviceSyncSessionSyncing) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: state.totalSessions > 0
                        ? state.syncedSessions / state.totalSessions
                        : null,
                  ),
                ],
                if (state is DeviceSyncActiveSession) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 4),
                  _buildActiveSessionInfo(state),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(DeviceSyncState state) {
    if (state is DeviceSyncTimeSyncing || state is DeviceSyncSessionSyncing) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (state is DeviceSyncTimeSynced || state is DeviceSyncSessionComplete) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 24);
    } else if (state is DeviceSyncTimeSyncFailed || state is DeviceSyncSessionFailed) {
      return const Icon(Icons.error, color: Colors.red, size: 24);
    } else if (state is DeviceSyncActiveSession) {
      return const Icon(Icons.play_circle, color: Colors.blue, size: 24);
    }
    return const Icon(Icons.sync, color: Colors.grey, size: 24);
  }

  String _getStatusTitle(DeviceSyncState state) {
    if (state is DeviceSyncTimeSyncing) {
      return 'Time Syncing...';
    } else if (state is DeviceSyncTimeSynced) {
      return 'Time Synced';
    } else if (state is DeviceSyncTimeSyncFailed) {
      return 'Time Sync Failed';
    } else if (state is DeviceSyncSessionSyncing) {
      return 'Syncing Sessions...';
    } else if (state is DeviceSyncSessionComplete) {
      return 'Sessions Synced';
    } else if (state is DeviceSyncSessionFailed) {
      return 'Session Sync Failed';
    } else if (state is DeviceSyncActiveSession) {
      return 'Session Active';
    }
    return 'Sync Status';
  }

  String _getStatusMessage(DeviceSyncState state) {
    if (state is DeviceSyncTimeSyncing) {
      return 'Synchronizing device time...';
    } else if (state is DeviceSyncTimeSynced) {
      return 'Device time synchronized';
    } else if (state is DeviceSyncTimeSyncFailed) {
      return state.message;
    } else if (state is DeviceSyncSessionSyncing) {
      return '${state.syncedSessions} / ${state.totalSessions} sessions';
    } else if (state is DeviceSyncSessionComplete) {
      return '${state.syncedCount} sessions synced';
    } else if (state is DeviceSyncSessionFailed) {
      return state.message;
    } else if (state is DeviceSyncActiveSession) {
      return 'Recording usage data...';
    }
    return '';
  }

  Widget _buildActiveSessionInfo(DeviceSyncActiveSession state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSessionInfoItem(
          Icons.radio_button_checked,
          state.shotType == 1 ? 'U-Shot' : 'E-Shot',
        ),
        _buildSessionInfoItem(
          Icons.tune,
          'Mode ${state.mode}',
        ),
        _buildSessionInfoItem(
          Icons.signal_cellular_alt,
          'Level ${state.level}',
        ),
      ],
    );
  }

  Widget _buildSessionInfoItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
