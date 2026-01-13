/// OTA error enum matching firmware OTAError
enum OtaError {
  none(0),
  lowBattery(1),
  invalidImage(2),
  writeFailed(3),
  checksumFailed(4),
  sizeExceeded(5),
  timeout(6),
  networkError(7),
  flashError(8),
  internalError(9),
  batteryDropped(10);

  const OtaError(this.value);
  final int value;

  static OtaError fromValue(int value) {
    return OtaError.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OtaError.none,
    );
  }

  String get message {
    switch (this) {
      case OtaError.none:
        return '';
      case OtaError.lowBattery:
        return 'Battery level too low for update';
      case OtaError.invalidImage:
        return 'Invalid firmware image';
      case OtaError.writeFailed:
        return 'Failed to write firmware';
      case OtaError.checksumFailed:
        return 'Firmware checksum verification failed';
      case OtaError.sizeExceeded:
        return 'Firmware size too large';
      case OtaError.timeout:
        return 'Update timed out';
      case OtaError.networkError:
        return 'Connection lost during update';
      case OtaError.flashError:
        return 'Flash memory error';
      case OtaError.internalError:
        return 'Internal error occurred';
      case OtaError.batteryDropped:
        return 'Battery dropped during update';
    }
  }
}
