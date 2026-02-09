// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'DualTetraX';

  @override
  String get home => 'หน้าหลัก';

  @override
  String get statistics => 'สถิติ';

  @override
  String get settings => 'การตั้งค่า';

  @override
  String get guide => 'คู่มือ';

  @override
  String get connectDevice => 'เชื่อมต่ออุปกรณ์';

  @override
  String connectionFailed(String message) {
    return 'การเชื่อมต่อล้มเหลว: $message';
  }

  @override
  String get retry => 'ลองอีกครั้ง';

  @override
  String get quickMenu => 'เมนูด่วน';

  @override
  String get usageHistory => 'ประวัติการใช้งาน';

  @override
  String get usageGuide => 'คู่มือการใช้งาน';

  @override
  String get connected => 'เชื่อมต่อแล้ว';

  @override
  String get connecting => 'กำลังเชื่อมต่อ...';

  @override
  String get disconnected => 'ไม่ได้เชื่อมต่อ';

  @override
  String get connectedToDevice => 'เชื่อมต่อกับ DualTetraX แล้ว';

  @override
  String get searchingDevice => 'กำลังค้นหาอุปกรณ์...';

  @override
  String get tapToConnect => 'แตะปุ่มเชื่อมต่อเพื่อเชื่อมต่อกับอุปกรณ์';

  @override
  String get shotType => 'ประเภท Shot';

  @override
  String get mode => 'โหมด';

  @override
  String get level => 'ระดับ';

  @override
  String get battery => 'แบตเตอรี่';

  @override
  String get shakeDevice => 'Please shake the device';

  @override
  String get todayUsage => 'การใช้งานวันนี้';

  @override
  String get totalUsageTime => 'เวลาใช้งานทั้งหมด';

  @override
  String get mostUsedMode => 'โหมดที่ใช้บ่อยที่สุด';

  @override
  String get noUsageData => 'ไม่มีข้อมูลการใช้งาน';

  @override
  String cannotLoadData(String message) {
    return 'ไม่สามารถโหลดข้อมูล: $message';
  }

  @override
  String get daily => 'รายวัน';

  @override
  String get weekly => 'รายสัปดาห์';

  @override
  String get monthly => 'รายเดือน';

  @override
  String get dailyUsageTime => 'เวลาใช้งานรายวัน';

  @override
  String get usageByType => 'การใช้งานตามประเภท Shot';

  @override
  String get usageByUShotMode => 'U-Shot Mode Usage';

  @override
  String get usageByEShotMode => 'E-Shot Mode Usage';

  @override
  String get minutes => 'นาที';

  @override
  String get secondsShort => 'sec';

  @override
  String get details => 'รายละเอียด';

  @override
  String get weeklyUsageTime => 'เวลาใช้งานรายสัปดาห์';

  @override
  String get dailyUsage => 'การใช้งานรายวัน';

  @override
  String get average => 'เฉลี่ย';

  @override
  String get minutesPerDay => 'นาที/วัน';

  @override
  String get monthlyUsageTime => 'เวลาใช้งานรายเดือน';

  @override
  String get usageTrend => 'แนวโน้มการใช้งาน';

  @override
  String get weeklyStatsComingSoon => 'สถิติรายสัปดาห์ (เร็วๆ นี้)';

  @override
  String get monthlyStatsComingSoon => 'สถิติรายเดือน (เร็วๆ นี้)';

  @override
  String error(String message) {
    return 'ข้อผิดพลาด: $message';
  }

  @override
  String get appearance => 'รูปลักษณ์';

  @override
  String get theme => 'ธีม';

  @override
  String get lightMode => 'โหมดสว่าง';

  @override
  String get darkMode => 'โหมดมืด';

  @override
  String get systemMode => 'ระบบ';

  @override
  String get selectTheme => 'เลือกธีม';

  @override
  String get device => 'อุปกรณ์';

  @override
  String get connectedDevice => 'อุปกรณ์ที่เชื่อมต่อ';

  @override
  String get disconnectDevice => 'ตัดการเชื่อมต่ออุปกรณ์';

  @override
  String get data => 'ข้อมูล';

  @override
  String get deleteAllData => 'ลบข้อมูลทั้งหมด';

  @override
  String get information => 'ข้อมูล';

  @override
  String get appVersion => 'เวอร์ชันแอป';

  @override
  String get termsOfService => 'เงื่อนไขการให้บริการ';

  @override
  String get privacyPolicy => 'นโยบายความเป็นส่วนตัว';

  @override
  String get deleteDataTitle => 'ลบข้อมูล';

  @override
  String get deleteDataMessage =>
      'ประวัติการใช้งานทั้งหมดจะถูกลบ\nการดำเนินการนี้ไม่สามารถยกเลิกได้\nคุณต้องการดำเนินการต่อหรือไม่?';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get delete => 'ลบ';

  @override
  String get allDataDeleted => 'ลบข้อมูลทั้งหมดแล้ว';

  @override
  String get language => 'ภาษา';

  @override
  String get selectLanguage => 'เลือกภาษา';

  @override
  String get shotTypeUnknown => 'ไม่ทราบ';

  @override
  String get shotTypeUShot => 'U-Shot';

  @override
  String get shotTypeEShot => 'E-Shot';

  @override
  String get shotTypeLedCare => 'LED Care';

  @override
  String get modeUnknown => 'ไม่ทราบ';

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
  String get modeLED => 'โหมด LED';

  @override
  String get levelUnknown => 'ไม่ทราบ';

  @override
  String get level1 => 'ระดับ 1';

  @override
  String get level2 => 'ระดับ 2';

  @override
  String get level3 => 'ระดับ 3';

  @override
  String get guideStep1Title => 'ขั้นตอนที่ 1: ชาร์จและเปิดเครื่อง';

  @override
  String get guideStep1Item1 => 'ชาร์จอุปกรณ์โดยใช้สาย USB-C';

  @override
  String get guideStep1Item2 =>
      'กดค้างปุ่มเปิด/ปิดเป็นเวลา 3 วินาทีเพื่อเปิดเครื่อง';

  @override
  String get guideStep1Item3 => 'อุปกรณ์เปิดใช้งานเมื่อไฟ LED สว่างขึ้น';

  @override
  String get guideStep2Title => 'ขั้นตอนที่ 2: สลับประเภท Shot';

  @override
  String get guideStep2Item1 =>
      'กดปุ่ม Shot เพื่อสลับระหว่าง U-Shot, E-Shot และ LED Care';

  @override
  String get guideStep2Item2 =>
      'คุณสามารถตรวจสอบประเภท Shot ปัจจุบันได้จากสี LED';

  @override
  String get guideStep3Title => 'ขั้นตอนที่ 3: เปลี่ยนโหมดและระดับ';

  @override
  String get guideStep3Item1 => 'กดปุ่มโหมดเพื่อเลือกโหมดที่ต้องการ';

  @override
  String get guideStep3Item2 => 'กดปุ่มระดับเพื่อปรับความเข้ม (ระดับ 1-3)';

  @override
  String get guideStep4Title => 'ขั้นตอนที่ 4: ข้อควรระวังระหว่างการใช้งาน';

  @override
  String get guideStep4Item1 =>
      'หากมีการเตือนอุณหภูมิ ให้หยุดใช้งานและปล่อยให้อุปกรณ์เย็นลง';

  @override
  String get guideStep4Item2 => 'หากมีการเตือนแบตเตอรี่ต่ำ จำเป็นต้องชาร์จ';

  @override
  String get guideStep4Item3 => 'การใช้งานมากเกินไปอาจทำให้ผิวระคายเคือง';

  @override
  String get guideStep5Title => 'ขั้นตอนที่ 5: ปิดเครื่องและเก็บรักษา';

  @override
  String get guideStep5Item1 =>
      'กดค้างปุ่มเปิด/ปิดเป็นเวลา 3 วินาทีเพื่อปิดเครื่อง';

  @override
  String get guideStep5Item2 =>
      'เช็ดทำความสะอาดอุปกรณ์ด้วยผ้าสะอาดก่อนเก็บรักษา';

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
  String get otaMode => 'โหมดอัปเดต OTA';

  @override
  String get otaInstructions =>
      'เชื่อมต่อกับอุปกรณ์ผ่าน WiFi และเข้าถึงเว็บอินเตอร์เฟซเพื่ออัปเดตเฟิร์มแวร์\n\nWiFi อุปกรณ์: DualTetraX-AP\nที่อยู่: http://192.168.4.1';

  @override
  String get sessionCompleted => 'เซสชันเสร็จสมบูรณ์';

  @override
  String get devicePoweredOff => 'อุปกรณ์ถูกปิด';

  @override
  String get autoReconnect => 'เชื่อมต่ออัตโนมัติ';

  @override
  String get autoReconnectInterval => 'ช่วงเวลาเชื่อมต่ออัตโนมัติ';

  @override
  String get seconds => 'วินาที';

  @override
  String get connectionMode => 'โหมดการเชื่อมต่อ';

  @override
  String get autoConnect => 'อัตโนมัติ';

  @override
  String get manualConnect => 'ด้วยตนเอง';

  @override
  String get firmwareUpdate => 'อัปเดตเฟิร์มแวร์';

  @override
  String get firmwareUpdateSubtitle => 'อัปเดตเฟิร์มแวร์อุปกรณ์ผ่าน Bluetooth';

  @override
  String get otaServiceNotAvailable => 'บริการ OTA ไม่พร้อมใช้งาน';

  @override
  String get otaUpdateCompleted => 'อัปเดตเสร็จสมบูรณ์';

  @override
  String get otaReadyForUpdate => 'พร้อมอัปเดต';

  @override
  String get deviceStatus => 'สถานะอุปกรณ์';

  @override
  String get firmware => 'เฟิร์มแวร์';

  @override
  String get noFirmwareSelected => 'ยังไม่ได้เลือกเฟิร์มแวร์';

  @override
  String get clear => 'ล้าง';

  @override
  String get selectFirmwareFile => 'เลือกไฟล์เฟิร์มแวร์';

  @override
  String get cancelUpdate => 'ยกเลิกการอัปเดต';

  @override
  String get startUpdate => 'เริ่มอัปเดต';

  @override
  String get otaStateIdle => 'ว่าง';

  @override
  String get otaStateDownloading => 'กำลังดาวน์โหลด...';

  @override
  String get otaStateValidating => 'กำลังตรวจสอบ...';

  @override
  String get otaStateInstalling => 'กำลังติดตั้ง...';

  @override
  String get otaStateComplete => 'เสร็จสมบูรณ์';

  @override
  String get otaStateError => 'ข้อผิดพลาด';

  @override
  String get updateComplete => 'อัปเดตเสร็จสมบูรณ์';

  @override
  String get updateCompleteMessage =>
      'อัปเดตเฟิร์มแวร์สำเร็จ อุปกรณ์จะรีสตาร์ทโดยอัตโนมัติ';

  @override
  String get ok => 'ตกลง';

  @override
  String get file => 'ไฟล์';

  @override
  String get version => 'เวอร์ชัน';

  @override
  String get size => 'ขนาด';

  @override
  String get deviceNotConnected => 'อุปกรณ์ไม่ได้เชื่อมต่อ';

  @override
  String sendingChunk(int sent, int total) {
    return 'กำลังส่งบล็อก $sent / $total';
  }

  @override
  String get syncedUsage => 'ซิงค์แล้ว';

  @override
  String get unsyncedUsage => 'เวลาโดยประมาณ';

  @override
  String get unsyncedTimeExplanation =>
      'เวลาโดยประมาณ: เซสชันที่บันทึกขณะแอปไม่ได้เชื่อมต่อ เวลาจริงอาจแตกต่างกัน';

  @override
  String get email => 'อีเมล';

  @override
  String get emailRequired => 'กรุณาระบุอีเมล';

  @override
  String get invalidEmail => 'กรุณาระบุอีเมลที่ถูกต้อง';

  @override
  String get password => 'รหัสผ่าน';

  @override
  String get passwordRequired => 'กรุณาระบุรหัสผ่าน';

  @override
  String get passwordTooShort => 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';

  @override
  String get passwordMismatch => 'รหัสผ่านไม่ตรงกัน';

  @override
  String get confirmPassword => 'ยืนยันรหัสผ่าน';

  @override
  String get forgotPassword => 'ลืมรหัสผ่าน?';

  @override
  String get login => 'เข้าสู่ระบบ';

  @override
  String get signup => 'สมัครสมาชิก';

  @override
  String get or => 'หรือ';

  @override
  String get continueWithGoogle => 'ดำเนินการต่อด้วย Google';

  @override
  String get continueWithApple => 'ดำเนินการต่อด้วย Apple';

  @override
  String get noAccount => 'ยังไม่มีบัญชี?';

  @override
  String get resetPassword => 'รีเซ็ตรหัสผ่าน';

  @override
  String get resetPasswordSent => 'ส่งอีเมลรีเซ็ตรหัสผ่านแล้ว';

  @override
  String get resetPasswordDescription =>
      'ระบุที่อยู่อีเมลของคุณ แล้วเราจะส่งลิงก์สำหรับรีเซ็ตรหัสผ่านให้คุณ';

  @override
  String get profile => 'โปรไฟล์';

  @override
  String get name => 'ชื่อ';

  @override
  String get gender => 'เพศ';

  @override
  String get male => 'ชาย';

  @override
  String get female => 'หญิง';

  @override
  String get other => 'อื่นๆ';

  @override
  String get save => 'บันทึก';

  @override
  String get account => 'บัญชี';

  @override
  String get logout => 'ออกจากระบบ';

  @override
  String get cloudSync => 'ซิงค์คลาวด์';

  @override
  String get syncToCloud => 'ซิงค์ไปยังคลาวด์';

  @override
  String get deviceNotRegistered => 'อุปกรณ์ยังไม่ได้ลงทะเบียนบนเซิร์ฟเวอร์';

  @override
  String get skinProfile => 'โปรไฟล์ผิว';

  @override
  String get logoutConfirmTitle => 'ออกจากระบบ';

  @override
  String get logoutConfirmMessage => 'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?';
}
