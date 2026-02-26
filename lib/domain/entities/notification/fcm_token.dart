import 'package:equatable/equatable.dart';

class FcmToken extends Equatable {
  final String userId;
  final String token;

  const FcmToken({required this.userId, required this.token});

  @override
  List<Object?> get props => [userId, token];
}
