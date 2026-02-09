import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/user_profile_model.dart';
import '../models/skin_profile_model.dart';
import '../models/notification_settings_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getProfile();
  Future<UserProfileModel> updateProfile({String? name, String? gender, String? dateOfBirth, String? timezone});
  Future<SkinProfileModel> getSkinProfile();
  Future<SkinProfileModel> updateSkinProfile({String? skinType, List<String>? concerns, String? memo});
  Future<NotificationSettingsModel> getNotificationSettings();
  Future<NotificationSettingsModel> updateNotificationSettings({
    bool? pushEnabled, bool? emailEnabled, bool? usageReminder, String? reminderTime, bool? marketingEnabled,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient _apiClient;

  ProfileRemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<UserProfileModel> getProfile() async {
    final response = await _apiClient.get(ApiEndpoints.profile);
    final data = response.data as Map<String, dynamic>;
    return UserProfileModel.fromJson(data['profile'] as Map<String, dynamic>);
  }

  @override
  Future<UserProfileModel> updateProfile({String? name, String? gender, String? dateOfBirth, String? timezone}) async {
    final response = await _apiClient.put(
      ApiEndpoints.profile,
      data: {
        if (name != null) 'name': name,
        if (gender != null) 'gender': gender,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
        if (timezone != null) 'timezone': timezone,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return UserProfileModel.fromJson(data['profile'] as Map<String, dynamic>);
  }

  @override
  Future<SkinProfileModel> getSkinProfile() async {
    final response = await _apiClient.get(ApiEndpoints.skinProfile);
    final data = response.data as Map<String, dynamic>;
    return SkinProfileModel.fromJson(data['skin_profile'] as Map<String, dynamic>);
  }

  @override
  Future<SkinProfileModel> updateSkinProfile({String? skinType, List<String>? concerns, String? memo}) async {
    final response = await _apiClient.put(
      ApiEndpoints.skinProfile,
      data: {
        if (skinType != null) 'skin_type': skinType,
        if (concerns != null) 'concerns': concerns,
        if (memo != null) 'memo': memo,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return SkinProfileModel.fromJson(data['skin_profile'] as Map<String, dynamic>);
  }

  @override
  Future<NotificationSettingsModel> getNotificationSettings() async {
    final response = await _apiClient.get(ApiEndpoints.notifications);
    final data = response.data as Map<String, dynamic>;
    return NotificationSettingsModel.fromJson(data['settings'] as Map<String, dynamic>);
  }

  @override
  Future<NotificationSettingsModel> updateNotificationSettings({
    bool? pushEnabled, bool? emailEnabled, bool? usageReminder, String? reminderTime, bool? marketingEnabled,
  }) async {
    final response = await _apiClient.put(
      ApiEndpoints.notifications,
      data: {
        if (pushEnabled != null) 'push_enabled': pushEnabled,
        if (emailEnabled != null) 'email_enabled': emailEnabled,
        if (usageReminder != null) 'usage_reminder': usageReminder,
        if (reminderTime != null) 'reminder_time': reminderTime,
        if (marketingEnabled != null) 'marketing_enabled': marketingEnabled,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return NotificationSettingsModel.fromJson(data['settings'] as Map<String, dynamic>);
  }
}
