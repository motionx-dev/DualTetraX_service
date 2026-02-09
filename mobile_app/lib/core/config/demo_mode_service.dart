import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DemoModeService {
  static const _demoModeKey = 'demo_mode_enabled';
  static const _developerOptionsKey = 'developer_options_enabled';

  final SharedPreferences _prefs;

  DemoModeService(this._prefs);

  bool get isAvailable => kDebugMode;

  bool get isEnabled => isAvailable && _prefs.getBool(_demoModeKey) == true;

  Future<void> setEnabled(bool value) async {
    await _prefs.setBool(_demoModeKey, value);
  }

  bool get isDeveloperOptionsEnabled =>
      isAvailable && _prefs.getBool(_developerOptionsKey) == true;

  Future<void> setDeveloperOptionsEnabled(bool value) async {
    await _prefs.setBool(_developerOptionsKey, value);
  }
}
