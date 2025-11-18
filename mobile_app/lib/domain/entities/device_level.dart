enum DeviceLevel {
  unknown(0x00, 'Unknown'),
  level1(0x01, 'Level 1'),
  level2(0x02, 'Level 2'),
  level3(0x03, 'Level 3');

  const DeviceLevel(this.value, this.displayName);
  final int value;
  final String displayName;

  static DeviceLevel fromValue(int value) {
    return DeviceLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => DeviceLevel.unknown,
    );
  }
}
