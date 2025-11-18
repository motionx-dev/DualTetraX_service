enum DeviceMode {
  unknown(0x00, 'Unknown'),
  // U-Shot modes
  glow(0x01, 'Glow'),
  tuning(0x02, 'Tuning'),
  renewal(0x03, 'Renewal'),
  volume(0x04, 'Volume'),
  // E-Shot modes
  cleansing(0x11, 'Cleansing'),
  firming(0x12, 'Firming'),
  lifting(0x13, 'Lifting'),
  lf(0x14, 'LF'),
  // LED Care mode
  ledMode(0x21, 'LED Mode');

  const DeviceMode(this.value, this.displayName);
  final int value;
  final String displayName;

  static DeviceMode fromValue(int value) {
    return DeviceMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => DeviceMode.unknown,
    );
  }

  bool get isUShotMode =>
      this == glow || this == tuning || this == renewal || this == volume;
  bool get isEShotMode =>
      this == cleansing || this == firming || this == lifting || this == lf;
  bool get isLEDMode => this == ledMode;
}
