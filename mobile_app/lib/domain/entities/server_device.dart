import 'package:equatable/equatable.dart';

class ServerDevice extends Equatable {
  final String id;
  final String userId;
  final String serialNumber;
  final String modelName;
  final String? firmwareVersion;
  final String? bleMacAddress;
  final String? nickname;
  final bool isActive;
  final DateTime registeredAt;
  final int totalSessions;
  final DateTime? lastSyncedAt;

  const ServerDevice({
    required this.id,
    required this.userId,
    required this.serialNumber,
    this.modelName = 'DualTetraX',
    this.firmwareVersion,
    this.bleMacAddress,
    this.nickname,
    this.isActive = true,
    required this.registeredAt,
    this.totalSessions = 0,
    this.lastSyncedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        serialNumber,
        modelName,
        firmwareVersion,
        bleMacAddress,
        nickname,
        isActive,
        registeredAt,
        totalSessions,
        lastSyncedAt,
      ];
}
