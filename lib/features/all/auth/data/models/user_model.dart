// lib/features/shared/domain/entities/organization.dart


// lib/features/shared/data/models/user_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    @JsonKey(name: 'password_hash') super.passwordHash,
    required super.name,
    super.phone,
    required super.role,
    @JsonKey(name: 'organization_id') required super.organizationId,
    super.locale,
    @JsonKey(name: 'profile_image_url') super.profileImageUrl,
    @JsonKey(name: 'is_active') required super.isActive,
    @JsonKey(name: 'is_verified') required super.isVerified,
    @JsonKey(name: 'fcm_token') super.fcmToken,
    @JsonKey(name: 'created_at') required super.createdAt,
    @JsonKey(name: 'updated_at') required super.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      passwordHash: user.passwordHash,
      name: user.name,
      phone: user.phone,
      role: user.role,
      organizationId: user.organizationId,
      locale: user.locale,
      profileImageUrl: user.profileImageUrl,
      isActive: user.isActive,
      isVerified: user.isVerified,
      fcmToken: user.fcmToken,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }
}

// Helper extension for UserRole enum
extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.employee:
        return 'employee';
      case UserRole.officeBoy:
        return 'office_boy';
    }
  }

  static UserRole fromString(String role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'employee':
        return UserRole.employee;
      case 'office_boy':
        return UserRole.officeBoy;
      default:
        throw ArgumentError('Invalid user role: $role');
    }
  }
}
