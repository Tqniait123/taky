import 'package:taqy/features/all/auth/data/models/user_model.dart';

class AuthModel {
  final UserModel user;
  final String? token;

  AuthModel({required this.user, this.token});

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      user: UserModel.fromJson(json['user']),
      token: json['access_token'],
      // hasSubscription: json['has_subscription'],
    );
  }
}
