// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'DualTetraX';

  @override
  String get home => '홈';

  @override
  String get statistics => '통계';

  @override
  String get settings => '설정';

  @override
  String get guide => '가이드';

  @override
  String get connectDevice => '디바이스 연결';

  @override
  String connectionFailed(String message) {
    return '연결 실패: $message';
  }

  @override
  String get retry => '재시도';

  @override
  String get quickMenu => '빠른 메뉴';

  @override
  String get usageHistory => '사용 기록';

  @override
  String get usageGuide => '사용 가이드';

  @override
  String get connected => '연결됨';

  @override
  String get connecting => '연결 중...';

  @override
  String get disconnected => '연결 안 됨';

  @override
  String get connectedToDevice => 'DualTetraX와 연결되었습니다';

  @override
  String get searchingDevice => '디바이스를 찾는 중입니다...';

  @override
  String get tapToConnect => '디바이스에 연결하려면 연결 버튼을 누르세요';

  @override
  String get shotType => 'Shot 타입';

  @override
  String get mode => '모드';

  @override
  String get level => '레벨';

  @override
  String get battery => '배터리';

  @override
  String get shakeDevice => '장치를 흔들어주세요';

  @override
  String get todayUsage => '오늘의 사용';

  @override
  String get totalUsageTime => '총 사용 시간';

  @override
  String get mostUsedMode => '가장 많이 사용한 모드';

  @override
  String get noUsageData => '사용 기록이 없습니다';

  @override
  String cannotLoadData(String message) {
    return '데이터를 불러올 수 없습니다: $message';
  }

  @override
  String get daily => '일';

  @override
  String get weekly => '주';

  @override
  String get monthly => '월';

  @override
  String get dailyUsageTime => '일별 사용 시간';

  @override
  String get usageByType => 'Shot 타입별 사용 시간';

  @override
  String get minutes => '분';

  @override
  String get weeklyStatsComingSoon => '주간 통계 (구현 예정)';

  @override
  String get monthlyStatsComingSoon => '월간 통계 (구현 예정)';

  @override
  String error(String message) {
    return '오류: $message';
  }

  @override
  String get appearance => '외관';

  @override
  String get theme => '테마';

  @override
  String get lightMode => '라이트 모드';

  @override
  String get darkMode => '다크 모드';

  @override
  String get systemMode => '시스템 설정';

  @override
  String get selectTheme => '테마 선택';

  @override
  String get device => '디바이스';

  @override
  String get connectedDevice => '연결된 디바이스';

  @override
  String get disconnectDevice => '디바이스 연결 해제';

  @override
  String get data => '데이터';

  @override
  String get deleteAllData => '모든 데이터 초기화';

  @override
  String get information => '정보';

  @override
  String get appVersion => '앱 버전';

  @override
  String get termsOfService => '이용약관';

  @override
  String get privacyPolicy => '개인정보 처리방침';

  @override
  String get deleteDataTitle => '데이터 초기화';

  @override
  String get deleteDataMessage =>
      '모든 사용 기록이 삭제됩니다.\\n이 작업은 취소할 수 없습니다.\\n계속하시겠습니까?';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get allDataDeleted => '모든 데이터가 삭제되었습니다';

  @override
  String get language => '언어';

  @override
  String get selectLanguage => '언어 선택';

  @override
  String get shotTypeUnknown => '알 수 없음';

  @override
  String get shotTypeUShot => 'U-Shot';

  @override
  String get shotTypeEShot => 'E-Shot';

  @override
  String get shotTypeLedCare => 'LED Care';

  @override
  String get modeUnknown => '알 수 없음';

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
  String get modeLED => 'LED 모드';

  @override
  String get levelUnknown => '알 수 없음';

  @override
  String get level1 => '레벨 1';

  @override
  String get level2 => '레벨 2';

  @override
  String get level3 => '레벨 3';

  @override
  String get guideStep1Title => '1단계: 디바이스 충전 및 전원 켜기';

  @override
  String get guideStep1Item1 => 'USB-C 케이블로 디바이스를 충전합니다';

  @override
  String get guideStep1Item2 => '전원 버튼을 3초 이상 눌러 전원을 켭니다';

  @override
  String get guideStep1Item3 => 'LED가 켜지면 전원이 켜진 것입니다';

  @override
  String get guideStep2Title => '2단계: Shot 타입 전환';

  @override
  String get guideStep2Item1 => 'Shot 버튼을 눌러 U-Shot, E-Shot, LED Care를 전환합니다';

  @override
  String get guideStep2Item2 => 'LED 색상으로 현재 Shot 타입을 확인할 수 있습니다';

  @override
  String get guideStep3Title => '3단계: 모드 및 레벨 변경';

  @override
  String get guideStep3Item1 => '모드 버튼을 눌러 원하는 모드를 선택합니다';

  @override
  String get guideStep3Item2 => '레벨 버튼을 눌러 강도를 조절합니다 (1~3단계)';

  @override
  String get guideStep4Title => '4단계: 사용 중 주의사항';

  @override
  String get guideStep4Item1 => '온도 경고가 발생하면 사용을 중지하고 디바이스를 식힙니다';

  @override
  String get guideStep4Item2 => '배터리 부족 경고가 발생하면 충전이 필요합니다';

  @override
  String get guideStep4Item3 => '과도한 사용은 피부에 자극을 줄 수 있습니다';

  @override
  String get guideStep5Title => '5단계: 전원 끄기 및 보관';

  @override
  String get guideStep5Item1 => '전원 버튼을 3초 이상 눌러 전원을 끕니다';

  @override
  String get guideStep5Item2 => '깨끗한 천으로 디바이스를 닦아 보관합니다';

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
  String get otaMode => 'OTA 업데이트 모드';

  @override
  String get otaInstructions =>
      'WiFi로 기기에 연결하여 웹 인터페이스에서 펌웨어를 업데이트하세요.\n\n기기 WiFi: DualTetraX-AP\n주소: http://192.168.4.1';

  @override
  String get sessionCompleted => '세션 완료';

  @override
  String get devicePoweredOff => '기기 전원이 꺼졌습니다';

  @override
  String get autoReconnect => '자동 재연결';

  @override
  String get autoReconnectInterval => '자동 재연결 간격';

  @override
  String get seconds => '초';

  @override
  String get connectionMode => '연결 모드';

  @override
  String get autoConnect => '자동';

  @override
  String get manualConnect => '수동';
}
