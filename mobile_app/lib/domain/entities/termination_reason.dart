enum TerminationReason {
  timeout8Min(0),
  manualPowerOff(1),
  batteryDrain(2),
  overheat(3),
  chargingStarted(4),
  pauseTimeout(5),
  modeSwitch(6),
  powerOn(7),
  overheatUltrasonic(8),
  overheatBody(9),
  other(255);

  final int value;
  const TerminationReason(this.value);

  static TerminationReason fromValue(int value) {
    return TerminationReason.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TerminationReason.other,
    );
  }

  String get displayName {
    switch (this) {
      case TerminationReason.timeout8Min:
        return '8min Timeout';
      case TerminationReason.manualPowerOff:
        return 'Manual Stop';
      case TerminationReason.batteryDrain:
        return 'Battery Depleted';
      case TerminationReason.overheat:
        return 'Overheat';
      case TerminationReason.chargingStarted:
        return 'Charging Started';
      case TerminationReason.pauseTimeout:
        return 'Pause Timeout';
      case TerminationReason.modeSwitch:
        return 'Mode Changed';
      case TerminationReason.powerOn:
        return 'Power On Event';
      case TerminationReason.overheatUltrasonic:
        return 'Ultrasonic Overheat';
      case TerminationReason.overheatBody:
        return 'Body Overheat';
      case TerminationReason.other:
        return 'Other';
    }
  }
}
