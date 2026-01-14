import 'package:equatable/equatable.dart';

class BatterySample extends Equatable {
  final int elapsedSeconds;
  final int voltageMV;

  const BatterySample({
    required this.elapsedSeconds,
    required this.voltageMV,
  });

  int get batteryPercent {
    if (voltageMV >= 4200) return 100;
    if (voltageMV <= 3000) return 0;

    if (voltageMV >= 4000) return 80 + ((voltageMV - 4000) * 20 ~/ 200);
    if (voltageMV >= 3700) return 20 + ((voltageMV - 3700) * 60 ~/ 300);
    return ((voltageMV - 3000) * 20 ~/ 700);
  }

  @override
  List<Object> get props => [elapsedSeconds, voltageMV];
}
