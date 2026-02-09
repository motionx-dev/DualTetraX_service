// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'DualTetraX';

  @override
  String get home => '主页';

  @override
  String get statistics => '统计';

  @override
  String get settings => '设置';

  @override
  String get guide => '指南';

  @override
  String get connectDevice => '连接设备';

  @override
  String connectionFailed(String message) {
    return '连接失败: $message';
  }

  @override
  String get retry => '重试';

  @override
  String get quickMenu => '快捷菜单';

  @override
  String get usageHistory => '使用记录';

  @override
  String get usageGuide => '使用指南';

  @override
  String get connected => '已连接';

  @override
  String get connecting => '连接中...';

  @override
  String get disconnected => '未连接';

  @override
  String get connectedToDevice => '已连接到 DualTetraX';

  @override
  String get searchingDevice => '正在搜索设备...';

  @override
  String get tapToConnect => '点击连接按钮以连接设备';

  @override
  String get shotType => 'Shot 类型';

  @override
  String get mode => '模式';

  @override
  String get level => '级别';

  @override
  String get battery => '电池';

  @override
  String get shakeDevice => 'Please shake the device';

  @override
  String get todayUsage => '今日使用';

  @override
  String get totalUsageTime => '总使用时间';

  @override
  String get mostUsedMode => '最常用模式';

  @override
  String get noUsageData => '没有使用数据';

  @override
  String cannotLoadData(String message) {
    return '无法加载数据: $message';
  }

  @override
  String get daily => '日';

  @override
  String get weekly => '周';

  @override
  String get monthly => '月';

  @override
  String get dailyUsageTime => '每日使用时间';

  @override
  String get usageByType => '按 Shot 类型统计使用时间';

  @override
  String get usageByUShotMode => 'U-Shot Mode Usage';

  @override
  String get usageByEShotMode => 'E-Shot Mode Usage';

  @override
  String get minutes => '分钟';

  @override
  String get secondsShort => 'sec';

  @override
  String get details => '详情';

  @override
  String get weeklyUsageTime => '每周使用时间';

  @override
  String get dailyUsage => '每日使用';

  @override
  String get average => '平均';

  @override
  String get minutesPerDay => '分钟/天';

  @override
  String get monthlyUsageTime => '每月使用时间';

  @override
  String get usageTrend => '使用趋势';

  @override
  String get weeklyStatsComingSoon => '每周统计（即将推出）';

  @override
  String get monthlyStatsComingSoon => '每月统计（即将推出）';

  @override
  String error(String message) {
    return '错误: $message';
  }

  @override
  String get appearance => '外观';

  @override
  String get theme => '主题';

  @override
  String get lightMode => '浅色模式';

  @override
  String get darkMode => '深色模式';

  @override
  String get systemMode => '系统设置';

  @override
  String get selectTheme => '选择主题';

  @override
  String get device => '设备';

  @override
  String get connectedDevice => '已连接的设备';

  @override
  String get disconnectDevice => '断开设备连接';

  @override
  String get data => '数据';

  @override
  String get deleteAllData => '删除所有数据';

  @override
  String get information => '信息';

  @override
  String get appVersion => '应用版本';

  @override
  String get termsOfService => '服务条款';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get deleteDataTitle => '删除数据';

  @override
  String get deleteDataMessage => '所有使用记录将被删除。\n此操作无法撤销。\n是否继续？';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get allDataDeleted => '所有数据已删除';

  @override
  String get language => '语言';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get shotTypeUnknown => '未知';

  @override
  String get shotTypeUShot => 'U-Shot';

  @override
  String get shotTypeEShot => 'E-Shot';

  @override
  String get shotTypeLedCare => 'LED Care';

  @override
  String get modeUnknown => '未知';

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
  String get modeLED => 'LED 模式';

  @override
  String get levelUnknown => '未知';

  @override
  String get level1 => '级别 1';

  @override
  String get level2 => '级别 2';

  @override
  String get level3 => '级别 3';

  @override
  String get guideStep1Title => '步骤 1：充电并开机';

  @override
  String get guideStep1Item1 => '使用 USB-C 线缆为设备充电';

  @override
  String get guideStep1Item2 => '按住电源按钮 3 秒以上以开机';

  @override
  String get guideStep1Item3 => 'LED 亮起时表示设备已开机';

  @override
  String get guideStep2Title => '步骤 2：切换 Shot 类型';

  @override
  String get guideStep2Item1 => '按 Shot 按钮在 U-Shot、E-Shot 和 LED Care 之间切换';

  @override
  String get guideStep2Item2 => '可以通过 LED 颜色查看当前 Shot 类型';

  @override
  String get guideStep3Title => '步骤 3：更改模式和级别';

  @override
  String get guideStep3Item1 => '按模式按钮选择所需模式';

  @override
  String get guideStep3Item2 => '按级别按钮调整强度（1-3 级）';

  @override
  String get guideStep4Title => '步骤 4：使用注意事项';

  @override
  String get guideStep4Item1 => '如果出现温度警告，请停止使用并让设备冷却';

  @override
  String get guideStep4Item2 => '如果出现低电量警告，需要充电';

  @override
  String get guideStep4Item3 => '过度使用可能会刺激皮肤';

  @override
  String get guideStep5Title => '步骤 5：关机和存储';

  @override
  String get guideStep5Item1 => '按住电源按钮 3 秒以上以关机';

  @override
  String get guideStep5Item2 => '用干净的布擦拭设备后存放';

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
  String get otaMode => 'OTA 更新模式';

  @override
  String get otaInstructions =>
      '通过WiFi连接设备并访问网页界面以更新固件。\n\n设备WiFi: DualTetraX-AP\n地址: http://192.168.4.1';

  @override
  String get sessionCompleted => '会话完成';

  @override
  String get devicePoweredOff => '设备已关机';

  @override
  String get autoReconnect => '自动重连';

  @override
  String get autoReconnectInterval => '自动重连间隔';

  @override
  String get seconds => '秒';

  @override
  String get connectionMode => '连接模式';

  @override
  String get autoConnect => '自动';

  @override
  String get manualConnect => '手动';

  @override
  String get firmwareUpdate => '固件更新';

  @override
  String get firmwareUpdateSubtitle => '通过蓝牙更新设备固件';

  @override
  String get otaServiceNotAvailable => 'OTA服务不可用';

  @override
  String get otaUpdateCompleted => '更新完成';

  @override
  String get otaReadyForUpdate => '准备更新';

  @override
  String get deviceStatus => '设备状态';

  @override
  String get firmware => '固件';

  @override
  String get noFirmwareSelected => '未选择固件';

  @override
  String get clear => '清除';

  @override
  String get selectFirmwareFile => '选择固件文件';

  @override
  String get cancelUpdate => '取消更新';

  @override
  String get startUpdate => '开始更新';

  @override
  String get otaStateIdle => '空闲';

  @override
  String get otaStateDownloading => '下载中...';

  @override
  String get otaStateValidating => '验证中...';

  @override
  String get otaStateInstalling => '安装中...';

  @override
  String get otaStateComplete => '完成';

  @override
  String get otaStateError => '错误';

  @override
  String get updateComplete => '更新完成';

  @override
  String get updateCompleteMessage => '固件更新成功。设备将自动重启。';

  @override
  String get ok => '确定';

  @override
  String get file => '文件';

  @override
  String get version => '版本';

  @override
  String get size => '大小';

  @override
  String get deviceNotConnected => '设备未连接';

  @override
  String sendingChunk(int sent, int total) {
    return '发送块 $sent / $total';
  }

  @override
  String get syncedUsage => '已同步';

  @override
  String get unsyncedUsage => '预估时间';

  @override
  String get unsyncedTimeExplanation => '预估时间：未连接应用时记录的会话。实际时间可能有所不同。';

  @override
  String get email => '电子邮件';

  @override
  String get emailRequired => '请输入电子邮件';

  @override
  String get invalidEmail => '请输入有效的电子邮件';

  @override
  String get password => '密码';

  @override
  String get passwordRequired => '请输入密码';

  @override
  String get passwordTooShort => '密码至少需要6个字符';

  @override
  String get passwordMismatch => '密码不匹配';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get login => '登录';

  @override
  String get signup => '注册';

  @override
  String get or => '或';

  @override
  String get continueWithGoogle => '使用Google继续';

  @override
  String get continueWithApple => '使用Apple继续';

  @override
  String get noAccount => '没有账号？';

  @override
  String get resetPassword => '重置密码';

  @override
  String get resetPasswordSent => '密码重置邮件已发送';

  @override
  String get resetPasswordDescription => '请输入您的电子邮件地址，我们将向您发送重置密码的链接。';

  @override
  String get profile => '个人资料';

  @override
  String get name => '姓名';

  @override
  String get gender => '性别';

  @override
  String get male => '男';

  @override
  String get female => '女';

  @override
  String get other => '其他';

  @override
  String get save => '保存';

  @override
  String get account => '账号';

  @override
  String get logout => '退出登录';

  @override
  String get cloudSync => '云同步';

  @override
  String get syncToCloud => '同步到云端';

  @override
  String get deviceNotRegistered => '设备未在服务器注册';

  @override
  String get skinProfile => '肤质档案';

  @override
  String get logoutConfirmTitle => '退出登录';

  @override
  String get logoutConfirmMessage => '确定要退出登录吗？';
}
