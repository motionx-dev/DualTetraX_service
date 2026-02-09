import '../../domain/entities/notification_settings.dart';

class NotificationSettingsModel extends NotificationSettings {
  const NotificationSettingsModel({
    required super.userId,
    super.pushEnabled,
    super.emailEnabled,
    super.usageReminder,
    super.reminderTime,
    super.marketingEnabled,
  });

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      userId: json['user_id'] as String,
      pushEnabled: json['push_enabled'] as bool? ?? true,
      emailEnabled: json['email_enabled'] as bool? ?? true,
      usageReminder: json['usage_reminder'] as bool? ?? false,
      reminderTime: json['reminder_time'] as String? ?? '09:00',
      marketingEnabled: json['marketing_enabled'] as bool? ?? false,
    );
  }
}
