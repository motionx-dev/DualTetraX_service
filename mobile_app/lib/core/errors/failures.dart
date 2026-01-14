import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class BleFailure extends Failure {
  const BleFailure(super.message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class DeviceNotFoundFailure extends Failure {
  const DeviceNotFoundFailure(super.message);
}

class ConnectionFailure extends Failure {
  const ConnectionFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}

class DeviceFailure extends Failure {
  const DeviceFailure(super.message);
}
