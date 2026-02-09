import '../../domain/entities/skin_profile.dart';

class SkinProfileModel extends SkinProfile {
  const SkinProfileModel({
    required super.userId,
    super.skinType,
    super.concerns,
    super.memo,
  });

  factory SkinProfileModel.fromJson(Map<String, dynamic> json) {
    return SkinProfileModel(
      userId: json['user_id'] as String,
      skinType: json['skin_type'] as String?,
      concerns: json['concerns'] != null
          ? List<String>.from(json['concerns'] as List)
          : const [],
      memo: json['memo'] as String?,
    );
  }
}
