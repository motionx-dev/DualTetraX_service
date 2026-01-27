/// Device mode enum matching firmware definitions
/// U-Shot: GLOW, TONEUP, RENEW, VOLUME
/// E-Shot: CLEAN, FIRM, LINE, LIFT
enum DeviceMode {
  unknown(0x00, 'Unknown', '-'),
  // U-Shot modes (firmware: UShotType)
  glow(0x01, 'Glow', 'GL'),
  toneup(0x02, 'Toneup', 'TN'),
  renew(0x03, 'Renew', 'RN'),
  volume(0x04, 'Volume', 'VL'),
  // E-Shot modes (firmware: EShotType)
  clean(0x11, 'Clean', 'CL'),
  firm(0x12, 'Firm', 'FM'),
  line(0x13, 'Line', 'LN'),
  lift(0x14, 'Lift', 'LF'),
  // LED Care mode
  ledMode(0x21, 'LED Mode', 'LED');

  const DeviceMode(this.value, this.displayName, this.shortName);
  final int value;
  final String displayName;
  final String shortName;

  static DeviceMode fromValue(int value) {
    return DeviceMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => DeviceMode.unknown,
    );
  }

  bool get isUShotMode =>
      this == glow || this == toneup || this == renew || this == volume;
  bool get isEShotMode =>
      this == clean || this == firm || this == line || this == lift;
  bool get isLEDMode => this == ledMode;
}
