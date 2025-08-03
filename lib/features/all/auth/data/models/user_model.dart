// lib/features/shared/data/models/user_model.dart
import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends User {
  // Define fields with JsonKey annotations
  @override
  final String id;

  @override
  final String email;

  @override
  @JsonKey(name: 'password_hash')
  final String? passwordHash;

  @override
  final String name;

  @override
  final String? phone;

  @override
  final UserRole role;

  @override
  @JsonKey(name: 'organization_id')
  final String organizationId;

  @override
  final String? locale;

  @override
  @JsonKey(name: 'profile_image_url')
  final String? profileImageUrl;

  @override
  @JsonKey(name: 'is_active')
  final bool isActive;

  @override
  @JsonKey(name: 'is_verified')
  final bool isVerified;

  @override
  @JsonKey(name: 'fcm_token')
  final String? fcmToken;

  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    this.passwordHash,
    required this.name,
    this.phone,
    required this.role,
    required this.organizationId,
    this.locale,
    this.profileImageUrl,
    required this.isActive,
    required this.isVerified,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  }) : super(
         id: id,
         email: email,
         passwordHash: passwordHash,
         name: name,
         phone: phone,
         role: role,
         organizationId: organizationId,
         locale: locale,
         profileImageUrl: profileImageUrl,
         isActive: isActive,
         isVerified: isVerified,
         fcmToken: fcmToken,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

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
