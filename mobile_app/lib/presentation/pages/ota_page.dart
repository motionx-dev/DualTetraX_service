import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/entities/ota_state.dart';
import '../bloc/ota/ota_bloc.dart';
import '../bloc/ota/ota_event.dart';
import '../bloc/ota/ota_state.dart';

class OtaPage extends StatefulWidget {
  const OtaPage({super.key});

  @override
  State<OtaPage> createState() => _OtaPageState();
}

class _OtaPageState extends State<OtaPage> {
  @override
  void initState() {
    super.initState();
    // Initialize OTA service when page opens
    context.read<OtaBloc>().add(const InitializeOtaRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.firmwareUpdate),
      ),
      body: BlocConsumer<OtaBloc, OtaBlocState>(
        listener: (context, state) {
          if (state.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
          if (state.isSuccess) {
            _showSuccessDialog(context);
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status card
                _buildStatusCard(context, state),
                const SizedBox(height: 16),

                // Firmware selection
                _buildFirmwareCard(context, state),
                const SizedBox(height: 16),

                // Progress section
                if (state.isOtaActive) ...[
                  _buildProgressCard(context, state),
                  const SizedBox(height: 16),
                ],

                const Spacer(),

                // Action buttons
                _buildActionButtons(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, OtaBlocState state) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    IconData icon;
    Color color;
    String status;

    if (!state.isOtaServiceReady) {
      icon = Icons.bluetooth_disabled;
      color = theme.colorScheme.error;
      status = l10n.otaServiceNotAvailable;
    } else if (state.isOtaActive) {
      icon = Icons.sync;
      color = theme.colorScheme.primary;
      // Use transferring status if actively sending chunks, otherwise use device state
      if (state.isTransferring) {
        status = l10n.otaStateDownloading;
      } else {
        status = _getOtaStateText(context, state.otaState);
      }
    } else if (state.isSuccess) {
      icon = Icons.check_circle;
      color = Colors.green;
      status = l10n.otaUpdateCompleted;
    } else if (state.isDeviceError) {
      icon = Icons.error;
      color = theme.colorScheme.error;
      status = state.deviceStatus?.error.message ?? l10n.otaStateError;
    } else {
      icon = Icons.bluetooth_connected;
      color = Colors.green;
      status = l10n.otaReadyForUpdate;
    }

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(l10n.deviceStatus),
        subtitle: Text(status),
        trailing: state.deviceStatus != null
            ? Text(
                '${state.deviceStatus!.batteryLevel}%',
                style: theme.textTheme.bodyLarge,
              )
            : null,
      ),
    );
  }

  Widget _buildFirmwareCard(BuildContext context, OtaBlocState state) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final firmware = state.selectedFirmware;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.firmware,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (firmware != null) ...[
              _buildFirmwareInfo(l10n.file, firmware.name),
              _buildFirmwareInfo(l10n.version, firmware.version),
              _buildFirmwareInfo(l10n.size, firmware.sizeFormatted),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: state.isOtaActive
                    ? null
                    : () {
                        context.read<OtaBloc>().add(const ClearFirmwareRequested());
                      },
                icon: const Icon(Icons.clear),
                label: Text(l10n.clear),
              ),
            ] else ...[
              Text(
                l10n.noFirmwareSelected,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: state.isOtaActive
                    ? null
                    : () {
                        context.read<OtaBloc>().add(const PickFirmwareRequested());
                      },
                icon: const Icon(Icons.folder_open),
                label: Text(l10n.selectFirmwareFile),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFirmwareInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, OtaBlocState state) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Use device progress if downloading, otherwise use send progress
    final progress = state.deviceStatus?.progress ?? state.sendProgress;
    final progressValue = progress / 100.0;

    // Show appropriate status text based on transfer state
    final statusText = state.isTransferring
        ? l10n.otaStateDownloading
        : _getOtaStateText(context, state.otaState);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  statusText,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  '$progress%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 12,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            if (state.isTransferring) ...[
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.sendingChunk(state.sentChunks, state.totalChunks),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, OtaBlocState state) {
    final l10n = AppLocalizations.of(context)!;

    if (state.isOtaActive) {
      return SizedBox(
        height: 56,
        child: FilledButton.icon(
          onPressed: () {
            context.read<OtaBloc>().add(const CancelOtaRequested());
          },
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          icon: const Icon(Icons.cancel),
          label: Text(l10n.cancelUpdate),
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: state.canStartOta
            ? () {
                context
                    .read<OtaBloc>()
                    .add(StartOtaRequested(state.selectedFirmware!));
              }
            : null,
        icon: const Icon(Icons.system_update),
        label: Text(l10n.startUpdate),
      ),
    );
  }

  String _getOtaStateText(BuildContext context, OtaState state) {
    final l10n = AppLocalizations.of(context)!;
    switch (state) {
      case OtaState.idle:
        return l10n.otaStateIdle;
      case OtaState.downloading:
        return l10n.otaStateDownloading;
      case OtaState.validating:
        return l10n.otaStateValidating;
      case OtaState.upgrading:
        return l10n.otaStateInstalling;
      case OtaState.success:
        return l10n.otaStateComplete;
      case OtaState.error:
        return l10n.otaStateError;
    }
  }

  void _showSuccessDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: Text(l10n.updateComplete),
        content: Text(l10n.updateCompleteMessage),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
}
