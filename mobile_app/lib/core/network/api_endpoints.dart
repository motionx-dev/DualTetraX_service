class ApiEndpoints {
  // Auth
  static const String logout = '/api/auth/logout';

  // Devices
  static const String devices = '/api/devices';
  static String device(String id) => '/api/devices/$id';
  static String deviceTransfer(String id) => '/api/devices/$id/transfer';

  // Sessions
  static const String sessions = '/api/sessions';
  static const String sessionsUpload = '/api/sessions/upload';
  static const String sessionsExport = '/api/sessions/export';
  static String session(String id) => '/api/sessions/$id';

  // Stats
  static const String statsDaily = '/api/stats/daily';
  static const String statsRange = '/api/stats/range';

  // Profile
  static const String profile = '/api/profile';
  static const String skinProfile = '/api/skin-profile';
  static const String notifications = '/api/notifications';
  static const String consent = '/api/consent';

  // Goals
  static const String goals = '/api/goals';
  static String goal(String id) => '/api/goals/$id';

  // Firmware
  static const String firmwareLatest = '/api/firmware/latest';
  static const String firmwareCheck = '/api/firmware/check';

  // Health
  static const String health = '/api/health';
  static const String ping = '/api/ping';
}
