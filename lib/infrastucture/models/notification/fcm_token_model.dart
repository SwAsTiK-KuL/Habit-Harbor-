import '../../../domain/entities/notification/fcm_token.dart';

class FcmTokenModel extends FcmToken {
  const FcmTokenModel({required super.userId, required super.token});

  factory FcmTokenModel.fromJson(Map<String, dynamic> json) {
    return FcmTokenModel(
      userId: json['user_id'] as String,
      token: json['fcm_token'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'user_id': userId, 'fcm_token': token};

  factory FcmTokenModel.fromEntity(FcmToken entity) {
    return FcmTokenModel(userId: entity.userId, token: entity.token);
  }
}
