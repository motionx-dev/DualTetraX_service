import 'package:equatable/equatable.dart';

class WarningStatus extends Equatable {
  final bool temperatureWarning;
  final bool batteryLowWarning;
  final bool batteryCriticalWarning;

  const WarningStatus({
    this.temperatureWarning = false,
    this.batteryLowWarning = false,
    this.batteryCriticalWarning = false,
  });

  factory WarningStatus.fromByte(int byte) {
    return WarningStatus(
      temperatureWarning: (byte & 0x01) != 0,
      batteryLowWarning: (byte & 0x02) != 0,
      batteryCriticalWarning: (byte & 0x04) != 0,
    );
  }

  bool get hasWarning =>
      temperatureWarning || batteryLowWarning || batteryCriticalWarning;

  @override
  List<Object?> get props =>
      [temperatureWarning, batteryLowWarning, batteryCriticalWarning];
}
