import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user_profile.dart';
import '../entities/skin_profile.dart';
import '../entities/notification_settings.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserProfile>> getProfile();
  Future<Either<Failure, UserProfile>> updateProfile({
    String? name,
    String? gender,
    String? dateOfBirth,
    String? timezone,
  });
  Future<Either<Failure, SkinProfile>> getSkinProfile();
  Future<Either<Failure, SkinProfile>> updateSkinProfile({
    String? skinType,
    List<String>? concerns,
    String? memo,
  });
  Future<Either<Failure, NotificationSettings>> getNotificationSettings();
  Future<Either<Failure, NotificationSettings>> updateNotificationSettings({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? usageReminder,
    String? reminderTime,
    bool? marketingEnabled,
  });
}
