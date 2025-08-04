// lib/features/all/auth/data/models/forget_password_params.dart
class ForgetPasswordParams {
  final String email;

  ForgetPasswordParams({
    required this.email,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
  };
}
