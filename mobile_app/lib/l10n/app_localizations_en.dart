// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DualTetraX';

  @override
  String get home => 'Home';

  @override
  String get statistics => 'Statistics';

  @override
  String get settings => 'Settings';

  @override
  String get guide => 'Guide';

  @override
  String get connectDevice => 'Connect Device';

  @override
  String connectionFailed(String message) {
    return 'Connection Failed: $message';
  }

  @override
  String get retry => 'Retry';

  @override
  String get quickMenu => 'Quick Menu';

  @override
  String get usageHistory => 'Usage History';

  @override
  String get usageGuide => 'Usage Guide';

  @override
  String get connected => 'Connected';

  @override
  String get connecting => 'Connecting...';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get connectedToDevice => 'Connected to DualTetraX';

  @override
  String get searchingDevice => 'Searching for device...';

  @override
  String get tapToConnect => 'Tap the connect button to connect to device';

  @override
  String get shotType => 'Shot Type';

  @override
  String get mode => 'Mode';

  @override
  String get level => 'Level';

  @override
  String get battery => 'Battery';

  @override
  String get shakeDevice => 'Please shake the device';

  @override
  String get todayUsage => 'Today\'s Usage';

  @override
  String get totalUsageTime => 'Total Usage Time';

  @override
  String get mostUsedMode => 'Most Used Mode';

  @override
  String get noUsageData => 'No usage data';

  @override
  String cannotLoadData(String message) {
    return 'Cannot load data: $message';
  }

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get dailyUsageTime => 'Daily Usage Time';

  @override
  String get usageByType => 'Usage by Shot Type';

  @override
  String get minutes => 'min';

  @override
  String get details => 'Details';

  @override
  String get weeklyUsageTime => 'Weekly Usage Time';

  @override
  String get dailyUsage => 'Daily Usage';

  @override
  String get average => 'Average';

  @override
  String get minutesPerDay => 'min/day';

  @override
  String get monthlyUsageTime => 'Monthly Usage Time';

  @override
  String get usageTrend => 'Usage Trend';

  @override
  String get weeklyStatsComingSoon => 'Weekly statistics (Coming soon)';

  @override
  String get monthlyStatsComingSoon => 'Monthly statistics (Coming soon)';

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get systemMode => 'System';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get device => 'Device';

  @override
  String get connectedDevice => 'Connected Device';

  @override
  String get disconnectDevice => 'Disconnect Device';

  @override
  String get data => 'Data';

  @override
  String get deleteAllData => 'Delete All Data';

  @override
  String get information => 'Information';

  @override
  String get appVersion => 'App Version';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get deleteDataTitle => 'Delete Data';

  @override
  String get deleteDataMessage =>
      'All usage history will be deleted.\\nThis action cannot be undone.\\nDo you want to continue?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get allDataDeleted => 'All data has been deleted';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get shotTypeUnknown => 'Unknown';

  @override
  String get shotTypeUShot => 'U-Shot';

  @override
  String get shotTypeEShot => 'E-Shot';

  @override
  String get shotTypeLedCare => 'LED Care';

  @override
  String get modeUnknown => 'Unknown';

  @override
  String get modeGlow => 'Glow';

  @override
  String get modeTuning => 'Tuning';

  @override
  String get modeRenewal => 'Renewal';

  @override
  String get modeVolume => 'Volume';

  @override
  String get modeCleansing => 'Cleansing';

  @override
  String get modeFirming => 'Firming';

  @override
  String get modeLifting => 'Lifting';

  @override
  String get modeLF => 'LF';

  @override
  String get modeLED => 'LED Mode';

  @override
  String get levelUnknown => 'Unknown';

  @override
  String get level1 => 'Level 1';

  @override
  String get level2 => 'Level 2';

  @override
  String get level3 => 'Level 3';

  @override
  String get guideStep1Title => 'Step 1: Charge and Power On';

  @override
  String get guideStep1Item1 => 'Charge the device using a USB-C cable';

  @override
  String get guideStep1Item2 =>
      'Press and hold the power button for 3 seconds to turn on';

  @override
  String get guideStep1Item3 => 'The device is on when the LED lights up';

  @override
  String get guideStep2Title => 'Step 2: Switch Shot Type';

  @override
  String get guideStep2Item1 =>
      'Press the Shot button to switch between U-Shot, E-Shot, and LED Care';

  @override
  String get guideStep2Item2 =>
      'You can check the current Shot type by LED color';

  @override
  String get guideStep3Title => 'Step 3: Change Mode and Level';

  @override
  String get guideStep3Item1 =>
      'Press the mode button to select the desired mode';

  @override
  String get guideStep3Item2 =>
      'Press the level button to adjust intensity (1-3 levels)';

  @override
  String get guideStep4Title => 'Step 4: Precautions During Use';

  @override
  String get guideStep4Item1 =>
      'If a temperature warning occurs, stop using and cool the device';

  @override
  String get guideStep4Item2 =>
      'If a low battery warning occurs, charging is required';

  @override
  String get guideStep4Item3 => 'Excessive use may irritate the skin';

  @override
  String get guideStep5Title => 'Step 5: Power Off and Storage';

  @override
  String get guideStep5Item1 =>
      'Press and hold the power button for 3 seconds to turn off';

  @override
  String get guideStep5Item2 =>
      'Wipe the device with a clean cloth before storing';

  @override
  String get korean => '한국어';

  @override
  String get english => 'English';

  @override
  String get chinese => '中文';

  @override
  String get japanese => '日本語';

  @override
  String get portuguese => 'Português';

  @override
  String get spanish => 'Español';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get thai => 'ไทย';

  @override
  String get otaMode => 'OTA UPDATE MODE';

  @override
  String get otaInstructions =>
      'Connect to the device via WiFi and access the web interface to update firmware.\n\nDevice WiFi: DualTetraX-AP\nAddress: http://192.168.4.1';

  @override
  String get sessionCompleted => 'Session Completed';

  @override
  String get devicePoweredOff => 'Device has been powered off';

  @override
  String get autoReconnect => 'Auto Reconnect';

  @override
  String get autoReconnectInterval => 'Auto Reconnect Interval';

  @override
  String get seconds => 'seconds';

  @override
  String get connectionMode => 'Connection Mode';

  @override
  String get autoConnect => 'Auto';

  @override
  String get manualConnect => 'Manual';

  @override
  String get firmwareUpdate => 'Firmware Update';

  @override
  String get firmwareUpdateSubtitle => 'Update device firmware via Bluetooth';

  @override
  String get otaServiceNotAvailable => 'OTA service not available';

  @override
  String get otaUpdateCompleted => 'Update completed';

  @override
  String get otaReadyForUpdate => 'Ready for update';

  @override
  String get deviceStatus => 'Device Status';

  @override
  String get firmware => 'Firmware';

  @override
  String get noFirmwareSelected => 'No firmware selected';

  @override
  String get clear => 'Clear';

  @override
  String get selectFirmwareFile => 'Select Firmware File';

  @override
  String get cancelUpdate => 'Cancel Update';

  @override
  String get startUpdate => 'Start Update';

  @override
  String get otaStateIdle => 'Idle';

  @override
  String get otaStateDownloading => 'Downloading...';

  @override
  String get otaStateValidating => 'Validating...';

  @override
  String get otaStateInstalling => 'Installing...';

  @override
  String get otaStateComplete => 'Complete';

  @override
  String get otaStateError => 'Error';

  @override
  String get updateComplete => 'Update Complete';

  @override
  String get updateCompleteMessage =>
      'Firmware update was successful. The device will restart automatically.';

  @override
  String get ok => 'OK';

  @override
  String get file => 'File';

  @override
  String get version => 'Version';

  @override
  String get size => 'Size';

  @override
  String get deviceNotConnected => 'Device is not connected';

  @override
  String sendingChunk(int sent, int total) {
    return 'Sending chunk $sent of $total';
  }
}
