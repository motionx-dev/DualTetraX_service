import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_th.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('th'),
    Locale('vi'),
    Locale('zh')
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'DualTetraX'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @guide.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get guide;

  /// No description provided for @connectDevice.
  ///
  /// In en, this message translates to:
  /// **'Connect Device'**
  String get connectDevice;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection Failed: {message}'**
  String connectionFailed(String message);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @quickMenu.
  ///
  /// In en, this message translates to:
  /// **'Quick Menu'**
  String get quickMenu;

  /// No description provided for @usageHistory.
  ///
  /// In en, this message translates to:
  /// **'Usage History'**
  String get usageHistory;

  /// No description provided for @usageGuide.
  ///
  /// In en, this message translates to:
  /// **'Usage Guide'**
  String get usageGuide;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @connectedToDevice.
  ///
  /// In en, this message translates to:
  /// **'Connected to DualTetraX'**
  String get connectedToDevice;

  /// No description provided for @searchingDevice.
  ///
  /// In en, this message translates to:
  /// **'Searching for device...'**
  String get searchingDevice;

  /// No description provided for @tapToConnect.
  ///
  /// In en, this message translates to:
  /// **'Tap the connect button to connect to device'**
  String get tapToConnect;

  /// No description provided for @shotType.
  ///
  /// In en, this message translates to:
  /// **'Shot Type'**
  String get shotType;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get battery;

  /// No description provided for @shakeDevice.
  ///
  /// In en, this message translates to:
  /// **'Please shake the device'**
  String get shakeDevice;

  /// No description provided for @todayUsage.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Usage'**
  String get todayUsage;

  /// No description provided for @totalUsageTime.
  ///
  /// In en, this message translates to:
  /// **'Total Usage Time'**
  String get totalUsageTime;

  /// No description provided for @mostUsedMode.
  ///
  /// In en, this message translates to:
  /// **'Most Used Mode'**
  String get mostUsedMode;

  /// No description provided for @noUsageData.
  ///
  /// In en, this message translates to:
  /// **'No usage data'**
  String get noUsageData;

  /// No description provided for @cannotLoadData.
  ///
  /// In en, this message translates to:
  /// **'Cannot load data: {message}'**
  String cannotLoadData(String message);

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @dailyUsageTime.
  ///
  /// In en, this message translates to:
  /// **'Daily Usage Time'**
  String get dailyUsageTime;

  /// No description provided for @usageByType.
  ///
  /// In en, this message translates to:
  /// **'Usage by Shot Type'**
  String get usageByType;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutes;

  /// No description provided for @weeklyStatsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Weekly statistics (Coming soon)'**
  String get weeklyStatsComingSoon;

  /// No description provided for @monthlyStatsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Monthly statistics (Coming soon)'**
  String get monthlyStatsComingSoon;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String error(String message);

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemMode;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @device.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get device;

  /// No description provided for @connectedDevice.
  ///
  /// In en, this message translates to:
  /// **'Connected Device'**
  String get connectedDevice;

  /// No description provided for @disconnectDevice.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Device'**
  String get disconnectDevice;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllData;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @deleteDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Data'**
  String get deleteDataTitle;

  /// No description provided for @deleteDataMessage.
  ///
  /// In en, this message translates to:
  /// **'All usage history will be deleted.\\nThis action cannot be undone.\\nDo you want to continue?'**
  String get deleteDataMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @allDataDeleted.
  ///
  /// In en, this message translates to:
  /// **'All data has been deleted'**
  String get allDataDeleted;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @shotTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get shotTypeUnknown;

  /// No description provided for @shotTypeUShot.
  ///
  /// In en, this message translates to:
  /// **'U-Shot'**
  String get shotTypeUShot;

  /// No description provided for @shotTypeEShot.
  ///
  /// In en, this message translates to:
  /// **'E-Shot'**
  String get shotTypeEShot;

  /// No description provided for @shotTypeLedCare.
  ///
  /// In en, this message translates to:
  /// **'LED Care'**
  String get shotTypeLedCare;

  /// No description provided for @modeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get modeUnknown;

  /// No description provided for @modeGlow.
  ///
  /// In en, this message translates to:
  /// **'Glow'**
  String get modeGlow;

  /// No description provided for @modeTuning.
  ///
  /// In en, this message translates to:
  /// **'Tuning'**
  String get modeTuning;

  /// No description provided for @modeRenewal.
  ///
  /// In en, this message translates to:
  /// **'Renewal'**
  String get modeRenewal;

  /// No description provided for @modeVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get modeVolume;

  /// No description provided for @modeCleansing.
  ///
  /// In en, this message translates to:
  /// **'Cleansing'**
  String get modeCleansing;

  /// No description provided for @modeFirming.
  ///
  /// In en, this message translates to:
  /// **'Firming'**
  String get modeFirming;

  /// No description provided for @modeLifting.
  ///
  /// In en, this message translates to:
  /// **'Lifting'**
  String get modeLifting;

  /// No description provided for @modeLF.
  ///
  /// In en, this message translates to:
  /// **'LF'**
  String get modeLF;

  /// No description provided for @modeLED.
  ///
  /// In en, this message translates to:
  /// **'LED Mode'**
  String get modeLED;

  /// No description provided for @levelUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get levelUnknown;

  /// No description provided for @level1.
  ///
  /// In en, this message translates to:
  /// **'Level 1'**
  String get level1;

  /// No description provided for @level2.
  ///
  /// In en, this message translates to:
  /// **'Level 2'**
  String get level2;

  /// No description provided for @level3.
  ///
  /// In en, this message translates to:
  /// **'Level 3'**
  String get level3;

  /// No description provided for @guideStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Step 1: Charge and Power On'**
  String get guideStep1Title;

  /// No description provided for @guideStep1Item1.
  ///
  /// In en, this message translates to:
  /// **'Charge the device using a USB-C cable'**
  String get guideStep1Item1;

  /// No description provided for @guideStep1Item2.
  ///
  /// In en, this message translates to:
  /// **'Press and hold the power button for 3 seconds to turn on'**
  String get guideStep1Item2;

  /// No description provided for @guideStep1Item3.
  ///
  /// In en, this message translates to:
  /// **'The device is on when the LED lights up'**
  String get guideStep1Item3;

  /// No description provided for @guideStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Step 2: Switch Shot Type'**
  String get guideStep2Title;

  /// No description provided for @guideStep2Item1.
  ///
  /// In en, this message translates to:
  /// **'Press the Shot button to switch between U-Shot, E-Shot, and LED Care'**
  String get guideStep2Item1;

  /// No description provided for @guideStep2Item2.
  ///
  /// In en, this message translates to:
  /// **'You can check the current Shot type by LED color'**
  String get guideStep2Item2;

  /// No description provided for @guideStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Step 3: Change Mode and Level'**
  String get guideStep3Title;

  /// No description provided for @guideStep3Item1.
  ///
  /// In en, this message translates to:
  /// **'Press the mode button to select the desired mode'**
  String get guideStep3Item1;

  /// No description provided for @guideStep3Item2.
  ///
  /// In en, this message translates to:
  /// **'Press the level button to adjust intensity (1-3 levels)'**
  String get guideStep3Item2;

  /// No description provided for @guideStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Step 4: Precautions During Use'**
  String get guideStep4Title;

  /// No description provided for @guideStep4Item1.
  ///
  /// In en, this message translates to:
  /// **'If a temperature warning occurs, stop using and cool the device'**
  String get guideStep4Item1;

  /// No description provided for @guideStep4Item2.
  ///
  /// In en, this message translates to:
  /// **'If a low battery warning occurs, charging is required'**
  String get guideStep4Item2;

  /// No description provided for @guideStep4Item3.
  ///
  /// In en, this message translates to:
  /// **'Excessive use may irritate the skin'**
  String get guideStep4Item3;

  /// No description provided for @guideStep5Title.
  ///
  /// In en, this message translates to:
  /// **'Step 5: Power Off and Storage'**
  String get guideStep5Title;

  /// No description provided for @guideStep5Item1.
  ///
  /// In en, this message translates to:
  /// **'Press and hold the power button for 3 seconds to turn off'**
  String get guideStep5Item1;

  /// No description provided for @guideStep5Item2.
  ///
  /// In en, this message translates to:
  /// **'Wipe the device with a clean cloth before storing'**
  String get guideStep5Item2;

  /// No description provided for @korean.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get korean;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get chinese;

  /// No description provided for @japanese.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get japanese;

  /// No description provided for @portuguese.
  ///
  /// In en, this message translates to:
  /// **'Português'**
  String get portuguese;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @vietnamese.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get vietnamese;

  /// No description provided for @thai.
  ///
  /// In en, this message translates to:
  /// **'ไทย'**
  String get thai;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'en',
        'es',
        'ja',
        'ko',
        'pt',
        'th',
        'vi',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'th':
      return AppLocalizationsTh();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
