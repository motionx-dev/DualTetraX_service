enum WorkingState {
  off(0x00, 'Off'),
  working(0x01, 'Working'),
  pause(0x02, 'Pause'),
  standby(0x03, 'Standby'),
  timeout(0x04, 'Timeout');  // Operation completed

  const WorkingState(this.value, this.displayName);
  final int value;
  final String displayName;

  static WorkingState fromValue(int value) {
    return WorkingState.values.firstWhere(
      (state) => state.value == value,
      orElse: () => WorkingState.off,
    );
  }
}
