// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'DualTetraX';

  @override
  String get home => 'ホーム';

  @override
  String get statistics => '統計';

  @override
  String get settings => '設定';

  @override
  String get guide => 'ガイド';

  @override
  String get connectDevice => 'デバイス接続';

  @override
  String connectionFailed(String message) {
    return '接続失敗: $message';
  }

  @override
  String get retry => '再試行';

  @override
  String get quickMenu => 'クイックメニュー';

  @override
  String get usageHistory => '使用履歴';

  @override
  String get usageGuide => '使用ガイド';

  @override
  String get connected => '接続済み';

  @override
  String get connecting => '接続中...';

  @override
  String get disconnected => '未接続';

  @override
  String get connectedToDevice => 'DualTetraXに接続しました';

  @override
  String get searchingDevice => 'デバイスを検索中...';

  @override
  String get tapToConnect => 'デバイスに接続するには接続ボタンをタップしてください';

  @override
  String get shotType => 'Shotタイプ';

  @override
  String get mode => 'モード';

  @override
  String get level => 'レベル';

  @override
  String get battery => 'バッテリー';

  @override
  String get shakeDevice => 'Please shake the device';

  @override
  String get todayUsage => '今日の使用';

  @override
  String get totalUsageTime => '総使用時間';

  @override
  String get mostUsedMode => '最も使用したモード';

  @override
  String get noUsageData => '使用データなし';

  @override
  String cannotLoadData(String message) {
    return 'データを読み込めません: $message';
  }

  @override
  String get daily => '日';

  @override
  String get weekly => '週';

  @override
  String get monthly => '月';

  @override
  String get dailyUsageTime => '1日の使用時間';

  @override
  String get usageByType => 'Shotタイプ別使用時間';

  @override
  String get usageByUShotMode => 'U-Shot Mode Usage';

  @override
  String get usageByEShotMode => 'E-Shot Mode Usage';

  @override
  String get minutes => '分';

  @override
  String get secondsShort => 'sec';

  @override
  String get details => '詳細';

  @override
  String get weeklyUsageTime => '週間使用時間';

  @override
  String get dailyUsage => '1日の使用';

  @override
  String get average => '平均';

  @override
  String get minutesPerDay => '分/日';

  @override
  String get monthlyUsageTime => '月間使用時間';

  @override
  String get usageTrend => '使用傾向';

  @override
  String get weeklyStatsComingSoon => '週間統計（近日公開）';

  @override
  String get monthlyStatsComingSoon => '月間統計（近日公開）';

  @override
  String error(String message) {
    return 'エラー: $message';
  }

  @override
  String get appearance => '外観';

  @override
  String get theme => 'テーマ';

  @override
  String get lightMode => 'ライトモード';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get systemMode => 'システム設定';

  @override
  String get selectTheme => 'テーマを選択';

  @override
  String get device => 'デバイス';

  @override
  String get connectedDevice => '接続済みデバイス';

  @override
  String get disconnectDevice => 'デバイス接続解除';

  @override
  String get data => 'データ';

  @override
  String get deleteAllData => 'すべてのデータを削除';

  @override
  String get information => '情報';

  @override
  String get appVersion => 'アプリバージョン';

  @override
  String get termsOfService => '利用規約';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get deleteDataTitle => 'データ削除';

  @override
  String get deleteDataMessage => 'すべての使用履歴が削除されます。\\nこの操作は元に戻せません。\\n続行しますか？';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get allDataDeleted => 'すべてのデータが削除されました';

  @override
  String get language => '言語';

  @override
  String get selectLanguage => '言語を選択';

  @override
  String get shotTypeUnknown => '不明';

  @override
  String get shotTypeUShot => 'U-Shot';

  @override
  String get shotTypeEShot => 'E-Shot';

  @override
  String get shotTypeLedCare => 'LED Care';

  @override
  String get modeUnknown => '不明';

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
  String get modeLED => 'LEDモード';

  @override
  String get levelUnknown => '不明';

  @override
  String get level1 => 'レベル 1';

  @override
  String get level2 => 'レベル 2';

  @override
  String get level3 => 'レベル 3';

  @override
  String get guideStep1Title => 'ステップ 1：充電と電源オン';

  @override
  String get guideStep1Item1 => 'USB-Cケーブルでデバイスを充電します';

  @override
  String get guideStep1Item2 => '電源ボタンを3秒以上長押しして電源を入れます';

  @override
  String get guideStep1Item3 => 'LEDが点灯すると電源がオンになります';

  @override
  String get guideStep2Title => 'ステップ 2：Shotタイプの切り替え';

  @override
  String get guideStep2Item1 => 'ShotボタンでU-Shot、E-Shot、LED Careを切り替えます';

  @override
  String get guideStep2Item2 => 'LEDの色で現在のShotタイプを確認できます';

  @override
  String get guideStep3Title => 'ステップ 3：モードとレベルの変更';

  @override
  String get guideStep3Item1 => 'モードボタンで希望のモードを選択します';

  @override
  String get guideStep3Item2 => 'レベルボタンで強度を調整します（1〜3レベル）';

  @override
  String get guideStep4Title => 'ステップ 4：使用中の注意事項';

  @override
  String get guideStep4Item1 => '温度警告が発生した場合は使用を中止し、デバイスを冷却してください';

  @override
  String get guideStep4Item2 => 'バッテリー低下警告が発生した場合は充電が必要です';

  @override
  String get guideStep4Item3 => '過度の使用は肌に刺激を与える可能性があります';

  @override
  String get guideStep5Title => 'ステップ 5：電源オフと保管';

  @override
  String get guideStep5Item1 => '電源ボタンを3秒以上長押しして電源を切ります';

  @override
  String get guideStep5Item2 => 'きれいな布でデバイスを拭いてから保管してください';

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
  String get otaMode => 'OTA アップデートモード';

  @override
  String get otaInstructions =>
      'WiFiで機器に接続し、ウェブインターフェースでファームウェアをアップデートしてください。\n\n機器WiFi: DualTetraX-AP\nアドレス: http://192.168.4.1';

  @override
  String get sessionCompleted => 'セッション完了';

  @override
  String get devicePoweredOff => 'デバイスの電源がオフになりました';

  @override
  String get autoReconnect => '自動再接続';

  @override
  String get autoReconnectInterval => '自動再接続間隔';

  @override
  String get seconds => '秒';

  @override
  String get connectionMode => '接続モード';

  @override
  String get autoConnect => '自動';

  @override
  String get manualConnect => '手動';

  @override
  String get firmwareUpdate => 'ファームウェア更新';

  @override
  String get firmwareUpdateSubtitle => 'Bluetoothでデバイスのファームウェアを更新';

  @override
  String get otaServiceNotAvailable => 'OTAサービスが利用できません';

  @override
  String get otaUpdateCompleted => '更新完了';

  @override
  String get otaReadyForUpdate => '更新準備完了';

  @override
  String get deviceStatus => 'デバイス状態';

  @override
  String get firmware => 'ファームウェア';

  @override
  String get noFirmwareSelected => 'ファームウェアが選択されていません';

  @override
  String get clear => 'クリア';

  @override
  String get selectFirmwareFile => 'ファームウェアファイルを選択';

  @override
  String get cancelUpdate => '更新をキャンセル';

  @override
  String get startUpdate => '更新を開始';

  @override
  String get otaStateIdle => '待機中';

  @override
  String get otaStateDownloading => 'ダウンロード中...';

  @override
  String get otaStateValidating => '検証中...';

  @override
  String get otaStateInstalling => 'インストール中...';

  @override
  String get otaStateComplete => '完了';

  @override
  String get otaStateError => 'エラー';

  @override
  String get updateComplete => '更新完了';

  @override
  String get updateCompleteMessage => 'ファームウェアの更新が成功しました。デバイスは自動的に再起動します。';

  @override
  String get ok => 'OK';

  @override
  String get file => 'ファイル';

  @override
  String get version => 'バージョン';

  @override
  String get size => 'サイズ';

  @override
  String get deviceNotConnected => 'デバイスが接続されていません';

  @override
  String sendingChunk(int sent, int total) {
    return 'チャンク送信中 $sent / $total';
  }

  @override
  String get syncedUsage => '同期済み';

  @override
  String get unsyncedUsage => '推定時間';

  @override
  String get unsyncedTimeExplanation =>
      '推定時間：アプリ未接続時に記録されたセッションです。実際の時間と異なる場合があります。';
}
