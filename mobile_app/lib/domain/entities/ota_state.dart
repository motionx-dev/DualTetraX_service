/// OTA state enum matching firmware OTAState
enum OtaState {
  idle(0),
  downloading(1),
  validating(2),
  upgrading(3),
  success(4),
  error(5);

  const OtaState(this.value);
  final int value;

  static OtaState fromValue(int value) {
    return OtaState.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OtaState.idle,
    );
  }

  bool get isActive =>
      this == OtaState.downloading ||
      this == OtaState.validating ||
      this == OtaState.upgrading;

  bool get isTerminal => this == OtaState.success || this == OtaState.error;
}
