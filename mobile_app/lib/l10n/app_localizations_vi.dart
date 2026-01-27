// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'DualTetraX';

  @override
  String get home => 'Trang chủ';

  @override
  String get statistics => 'Thống kê';

  @override
  String get settings => 'Cài đặt';

  @override
  String get guide => 'Hướng dẫn';

  @override
  String get connectDevice => 'Kết nối Thiết bị';

  @override
  String connectionFailed(String message) {
    return 'Kết nối Thất bại: $message';
  }

  @override
  String get retry => 'Thử lại';

  @override
  String get quickMenu => 'Menu Nhanh';

  @override
  String get usageHistory => 'Lịch sử Sử dụng';

  @override
  String get usageGuide => 'Hướng dẫn Sử dụng';

  @override
  String get connected => 'Đã kết nối';

  @override
  String get connecting => 'Đang kết nối...';

  @override
  String get disconnected => 'Chưa kết nối';

  @override
  String get connectedToDevice => 'Đã kết nối với DualTetraX';

  @override
  String get searchingDevice => 'Đang tìm thiết bị...';

  @override
  String get tapToConnect => 'Nhấn nút kết nối để kết nối với thiết bị';

  @override
  String get shotType => 'Loại Shot';

  @override
  String get mode => 'Chế độ';

  @override
  String get level => 'Cấp độ';

  @override
  String get battery => 'Pin';

  @override
  String get shakeDevice => 'Please shake the device';

  @override
  String get todayUsage => 'Sử dụng Hôm nay';

  @override
  String get totalUsageTime => 'Tổng Thời gian Sử dụng';

  @override
  String get mostUsedMode => 'Chế độ Được Sử dụng Nhiều Nhất';

  @override
  String get noUsageData => 'Không có dữ liệu sử dụng';

  @override
  String cannotLoadData(String message) {
    return 'Không thể tải dữ liệu: $message';
  }

  @override
  String get daily => 'Ngày';

  @override
  String get weekly => 'Tuần';

  @override
  String get monthly => 'Tháng';

  @override
  String get dailyUsageTime => 'Thời gian Sử dụng Hàng ngày';

  @override
  String get usageByType => 'Sử dụng theo Loại Shot';

  @override
  String get usageByUShotMode => 'U-Shot Mode Usage';

  @override
  String get usageByEShotMode => 'E-Shot Mode Usage';

  @override
  String get minutes => 'phút';

  @override
  String get secondsShort => 'sec';

  @override
  String get details => 'Chi tiết';

  @override
  String get weeklyUsageTime => 'Thời gian Sử dụng Hàng tuần';

  @override
  String get dailyUsage => 'Sử dụng Hàng ngày';

  @override
  String get average => 'Trung bình';

  @override
  String get minutesPerDay => 'phút/ngày';

  @override
  String get monthlyUsageTime => 'Thời gian Sử dụng Hàng tháng';

  @override
  String get usageTrend => 'Xu hướng Sử dụng';

  @override
  String get weeklyStatsComingSoon => 'Thống kê hàng tuần (Sắp có)';

  @override
  String get monthlyStatsComingSoon => 'Thống kê hàng tháng (Sắp có)';

  @override
  String error(String message) {
    return 'Lỗi: $message';
  }

  @override
  String get appearance => 'Giao diện';

  @override
  String get theme => 'Chủ đề';

  @override
  String get lightMode => 'Chế độ Sáng';

  @override
  String get darkMode => 'Chế độ Tối';

  @override
  String get systemMode => 'Hệ thống';

  @override
  String get selectTheme => 'Chọn Chủ đề';

  @override
  String get device => 'Thiết bị';

  @override
  String get connectedDevice => 'Thiết bị Đã kết nối';

  @override
  String get disconnectDevice => 'Ngắt kết nối Thiết bị';

  @override
  String get data => 'Dữ liệu';

  @override
  String get deleteAllData => 'Xóa Tất cả Dữ liệu';

  @override
  String get information => 'Thông tin';

  @override
  String get appVersion => 'Phiên bản Ứng dụng';

  @override
  String get termsOfService => 'Điều khoản Dịch vụ';

  @override
  String get privacyPolicy => 'Chính sách Bảo mật';

  @override
  String get deleteDataTitle => 'Xóa Dữ liệu';

  @override
  String get deleteDataMessage =>
      'Tất cả lịch sử sử dụng sẽ bị xóa.\\nHành động này không thể hoàn tác.\\nBạn có muốn tiếp tục?';

  @override
  String get cancel => 'Hủy';

  @override
  String get delete => 'Xóa';

  @override
  String get allDataDeleted => 'Tất cả dữ liệu đã được xóa';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get selectLanguage => 'Chọn Ngôn ngữ';

  @override
  String get shotTypeUnknown => 'Không xác định';

  @override
  String get shotTypeUShot => 'U-Shot';

  @override
  String get shotTypeEShot => 'E-Shot';

  @override
  String get shotTypeLedCare => 'LED Care';

  @override
  String get modeUnknown => 'Không xác định';

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
  String get modeLED => 'Chế độ LED';

  @override
  String get levelUnknown => 'Không xác định';

  @override
  String get level1 => 'Cấp độ 1';

  @override
  String get level2 => 'Cấp độ 2';

  @override
  String get level3 => 'Cấp độ 3';

  @override
  String get guideStep1Title => 'Bước 1: Sạc và Bật nguồn';

  @override
  String get guideStep1Item1 => 'Sạc thiết bị bằng cáp USB-C';

  @override
  String get guideStep1Item2 => 'Nhấn và giữ nút nguồn trong 3 giây để bật';

  @override
  String get guideStep1Item3 => 'Thiết bị được bật khi đèn LED sáng lên';

  @override
  String get guideStep2Title => 'Bước 2: Chuyển đổi Loại Shot';

  @override
  String get guideStep2Item1 =>
      'Nhấn nút Shot để chuyển đổi giữa U-Shot, E-Shot và LED Care';

  @override
  String get guideStep2Item2 =>
      'Bạn có thể kiểm tra loại Shot hiện tại bằng màu LED';

  @override
  String get guideStep3Title => 'Bước 3: Thay đổi Chế độ và Cấp độ';

  @override
  String get guideStep3Item1 => 'Nhấn nút chế độ để chọn chế độ mong muốn';

  @override
  String get guideStep3Item2 =>
      'Nhấn nút cấp độ để điều chỉnh cường độ (cấp độ 1-3)';

  @override
  String get guideStep4Title => 'Bước 4: Cảnh báo Khi Sử dụng';

  @override
  String get guideStep4Item1 =>
      'Nếu xuất hiện cảnh báo nhiệt độ, hãy ngừng sử dụng và để thiết bị nguội';

  @override
  String get guideStep4Item2 => 'Nếu xuất hiện cảnh báo pin yếu, cần sạc';

  @override
  String get guideStep4Item3 => 'Sử dụng quá mức có thể gây kích ứng da';

  @override
  String get guideStep5Title => 'Bước 5: Tắt nguồn và Bảo quản';

  @override
  String get guideStep5Item1 => 'Nhấn và giữ nút nguồn trong 3 giây để tắt';

  @override
  String get guideStep5Item2 =>
      'Lau sạch thiết bị bằng khăn sạch trước khi bảo quản';

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
  String get otaMode => 'CHẾ ĐỘ CẬP NHẬT OTA';

  @override
  String get otaInstructions =>
      'Kết nối với thiết bị qua WiFi và truy cập giao diện web để cập nhật firmware.\n\nWiFi thiết bị: DualTetraX-AP\nĐịa chỉ: http://192.168.4.1';

  @override
  String get sessionCompleted => 'Phiên Hoàn tất';

  @override
  String get devicePoweredOff => 'Thiết bị đã tắt nguồn';

  @override
  String get autoReconnect => 'Tự động Kết nối lại';

  @override
  String get autoReconnectInterval => 'Khoảng thời gian Kết nối lại';

  @override
  String get seconds => 'giây';

  @override
  String get connectionMode => 'Chế độ Kết nối';

  @override
  String get autoConnect => 'Tự động';

  @override
  String get manualConnect => 'Thủ công';

  @override
  String get firmwareUpdate => 'Cập nhật Firmware';

  @override
  String get firmwareUpdateSubtitle =>
      'Cập nhật firmware thiết bị qua Bluetooth';

  @override
  String get otaServiceNotAvailable => 'Dịch vụ OTA không khả dụng';

  @override
  String get otaUpdateCompleted => 'Cập nhật hoàn tất';

  @override
  String get otaReadyForUpdate => 'Sẵn sàng cập nhật';

  @override
  String get deviceStatus => 'Trạng thái Thiết bị';

  @override
  String get firmware => 'Firmware';

  @override
  String get noFirmwareSelected => 'Chưa chọn firmware';

  @override
  String get clear => 'Xóa';

  @override
  String get selectFirmwareFile => 'Chọn Tệp Firmware';

  @override
  String get cancelUpdate => 'Hủy Cập nhật';

  @override
  String get startUpdate => 'Bắt đầu Cập nhật';

  @override
  String get otaStateIdle => 'Chờ';

  @override
  String get otaStateDownloading => 'Đang tải...';

  @override
  String get otaStateValidating => 'Đang xác thực...';

  @override
  String get otaStateInstalling => 'Đang cài đặt...';

  @override
  String get otaStateComplete => 'Hoàn tất';

  @override
  String get otaStateError => 'Lỗi';

  @override
  String get updateComplete => 'Cập nhật Hoàn tất';

  @override
  String get updateCompleteMessage =>
      'Cập nhật firmware thành công. Thiết bị sẽ tự động khởi động lại.';

  @override
  String get ok => 'OK';

  @override
  String get file => 'Tệp';

  @override
  String get version => 'Phiên bản';

  @override
  String get size => 'Kích thước';

  @override
  String get deviceNotConnected => 'Thiết bị chưa được kết nối';

  @override
  String sendingChunk(int sent, int total) {
    return 'Đang gửi khối $sent / $total';
  }

  @override
  String get syncedUsage => 'Đã đồng bộ';

  @override
  String get unsyncedUsage => 'Thời gian ước tính';

  @override
  String get unsyncedTimeExplanation =>
      'Thời gian ước tính: Phiên được ghi khi ứng dụng bị ngắt kết nối. Thời gian thực tế có thể khác.';
}
