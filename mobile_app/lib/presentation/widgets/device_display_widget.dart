import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/entities/device_status.dart';
import '../../domain/entities/shot_type.dart';
import '../../domain/entities/device_mode.dart';
import '../../domain/entities/device_level.dart';
import '../../domain/entities/working_state.dart';
import '../bloc/device_status/device_status_bloc.dart';

/// Widget that simulates the DualTetraX device display with LED overlays
class DeviceDisplayWidget extends StatefulWidget {
  const DeviceDisplayWidget({super.key});

  @override
  State<DeviceDisplayWidget> createState() => _DeviceDisplayWidgetState();
}

class _DeviceDisplayWidgetState extends State<DeviceDisplayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  static const String _deviceImagePath = 'assets/images/device.png';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceStatusBloc, DeviceStatusState>(
      builder: (context, state) {
        if (state is DeviceStatusLoaded) {
          return _buildDisplay(context, state.status);
        }
        return _buildEmptyDisplay(context);
      },
    );
  }

  Widget _buildDisplay(BuildContext context, DeviceStatus status) {
    final needsMotion = status.shotType == ShotType.uShot &&
        status.workingState == WorkingState.working &&
        !status.isMotionDetected;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              children: [
                if (needsMotion)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.orange.withOpacity(_pulseAnimation.value),
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(_pulseAnimation.value * 0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                _buildDeviceImage(),
                _buildLEDOverlays(status),
              ],
            ),
          ),

          if (needsMotion) ...[
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.orange,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.vibration,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.shakeDevice,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],

          // Show timer for both working and pause states
          if ((status.workingState == WorkingState.working ||
               status.workingState == WorkingState.pause) &&
              status.totalWorkingTime != null &&
              status.currentWorkingTime != null) ...[
            const SizedBox(height: 16),
            _buildTimerDisplay(status),
          ],

          // Show pause indicator
          if (status.workingState == WorkingState.pause) ...[
            const SizedBox(height: 12),
            _buildPauseIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyDisplay(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Stack(
          children: [
            _buildDeviceImage(opacity: 0.5),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.disconnected,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceImage({double opacity = 1.0}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageFile = File(_deviceImagePath);

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Opacity(
              opacity: opacity,
              child: _buildImageOrPlaceholder(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageOrPlaceholder() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Image.asset(
          _deviceImagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFF2A2A2A),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 64,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Device Image\nPlaceholder',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLEDOverlays(DeviceStatus status) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          children: [
            Positioned(
              top: height * 0.12,
              left: 0,
              right: 0,
              child: _buildShotTypeOverlay(status.shotType, width),
            ),
            Positioned(
              top: height * 0.30,
              left: 0,
              right: 0,
              child: _buildAllModesOverlay(status.shotType, status.mode, width),
            ),
            Positioned(
              bottom: height * 0.12,
              left: 0,
              right: 0,
              child: _buildLevelOverlay(
                status.level,
                status.batteryStatus.level,
                width,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShotTypeOverlay(ShotType shotType, double width) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildShotTypeIndicator('U', shotType == ShotType.uShot),
        SizedBox(width: width * 0.15),
        _buildShotTypeIndicator('E', shotType == ShotType.eShot),
      ],
    );
  }

  Widget _buildAllModesOverlay(ShotType shotType, DeviceMode mode, double width) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildModeIndicator('GL', shotType == ShotType.uShot && mode == DeviceMode.glow),
            SizedBox(width: width * 0.20),
            _buildModeIndicator('CL', shotType == ShotType.eShot && mode == DeviceMode.cleansing),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildModeIndicator('TN', shotType == ShotType.uShot && mode == DeviceMode.tuning),
            SizedBox(width: width * 0.20),
            _buildModeIndicator('FM', shotType == ShotType.eShot && mode == DeviceMode.firming),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildModeIndicator('RE', shotType == ShotType.uShot && mode == DeviceMode.renewal),
            SizedBox(width: width * 0.20),
            _buildModeIndicator('LN', shotType == ShotType.eShot && mode == DeviceMode.lifting),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildModeIndicator('VO', shotType == ShotType.uShot && mode == DeviceMode.volume),
            SizedBox(width: width * 0.20),
            _buildModeIndicator('LF', shotType == ShotType.eShot && mode == DeviceMode.lf),
          ],
        ),
      ],
    );
  }

  Widget _buildLevelOverlay(DeviceLevel level, int batteryLevel, double width) {
    final levelCount = level == DeviceLevel.level1
        ? 1
        : level == DeviceLevel.level2
            ? 2
            : level == DeviceLevel.level3
                ? 3
                : 0;  // unknown level shows no dots

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDotGlow(levelCount >= 1, false),
        SizedBox(width: width * 0.06),
        _buildDotGlow(levelCount >= 2, false),
        SizedBox(width: width * 0.06),
        _buildDotGlow(levelCount >= 3, false),
      ],
    );
  }

  Widget _buildShotTypeIndicator(String label, bool isActive) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.green : Colors.grey.shade800,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildModeIndicator(String label, bool isActive) {
    return Container(
      width: 50,
      height: 28,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w400,
            color: isActive ? Colors.white : Colors.grey.shade600,
            letterSpacing: 0.8,
            shadows: isActive
                ? [
                    Shadow(
                      color: Colors.white.withOpacity(0.7),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDotGlow(bool isActive, bool isWarning) {
    Color color;
    if (isWarning) {
      color = Colors.yellow;
    } else if (isActive) {
      color = Colors.white;
    } else {
      color = Colors.grey.shade800;
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(isActive || isWarning ? 0.9 : 1.0),
        boxShadow: (isActive || isWarning)
            ? [
                BoxShadow(
                  color: color.withOpacity(0.8),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildTimerDisplay(DeviceStatus status) {
    final current = status.currentWorkingTime!;
    final total = status.totalWorkingTime!;
    final progress = current / total;

    String formatTime(int seconds) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.timer,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatTime(current),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              Text(
                formatTime(total),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 진행 바
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseIndicator() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.amber.withOpacity(_pulseAnimation.value),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pause_circle_filled,
                color: Colors.amber.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'PAUSED',
                style: TextStyle(
                  color: Colors.amber.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
