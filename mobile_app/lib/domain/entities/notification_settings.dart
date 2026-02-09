import 'package:equatable/equatable.dart';

class NotificationSettings extends Equatable {
  final String userId;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool usageReminder;
  final String reminderTime;
  final bool marketingEnabled;

  const NotificationSettings({
    required this.userId,
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.usageReminder = false,
    this.reminderTime = '09:00',
    this.marketingEnabled = false,
  });

  @override
  List<Object?> get props => [
        userId,
        pushEnabled,
        emailEnabled,
        usageReminder,
        reminderTime,
        marketingEnabled,
      ];
}
