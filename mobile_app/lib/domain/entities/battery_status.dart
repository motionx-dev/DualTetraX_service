import 'package:equatable/equatable.dart';

enum BatteryState {
  sufficient(0x01, 'Sufficient'),
  low(0x02, 'Low'),
  critical(0x03, 'Critical'),
  charging(0x04, 'Charging');

  const BatteryState(this.value, this.displayName);
  final int value;
  final String displayName;

  static BatteryState fromValue(int value) {
    return BatteryState.values.firstWhere(
      (state) => state.value == value,
      orElse: () => BatteryState.sufficient,
    );
  }
}

class BatteryStatus extends Equatable {
  final int level; // 0-100
  final BatteryState state;

  const BatteryStatus({
    required this.level,
    required this.state,
  });

  @override
  List<Object?> get props => [level, state];
}
