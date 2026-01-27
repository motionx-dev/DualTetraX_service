/// Shot type enum matching firmware FeatureType (0-based)
/// Firmware: USHOT=0, ESHOT=1, OPTO_MODE=2
enum ShotType {
  uShot(0x00, 'U-Shot'),
  eShot(0x01, 'E-Shot'),
  ledCare(0x02, 'LED Care'),
  unknown(0xFF, 'Unknown');

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
