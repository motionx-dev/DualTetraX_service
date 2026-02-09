import 'package:equatable/equatable.dart';

class SkinProfile extends Equatable {
  final String userId;
  final String? skinType;
  final List<String> concerns;
  final String? memo;

  const SkinProfile({
    required this.userId,
    this.skinType,
    this.concerns = const [],
    this.memo,
  });

  @override
  List<Object?> get props => [userId, skinType, concerns, memo];
}
