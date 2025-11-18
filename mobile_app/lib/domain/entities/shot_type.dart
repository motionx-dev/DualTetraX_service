enum ShotType {
  unknown(0x00, 'Unknown'),
  uShot(0x01, 'U-Shot'),
  eShot(0x02, 'E-Shot'),
  ledCare(0x03, 'LED Care');

  const ShotType(this.value, this.displayName);
  final int value;
  final String displayName;

  static ShotType fromValue(int value) {
    return ShotType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ShotType.unknown,
    );
  }
}
