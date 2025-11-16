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
  final String? passwordHash;
  @override
  final String name;
  @override
  final String? phone;
  @override
  final UserRole role;
  @override
  final String organizationId;
  @override
  final String? locale;
  @override
  final String? profileImageUrl;
  @override
  final bool isActive;
  @override
  final bool isVerified;
  @override
  final String? fcmToken;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
   @override
  final String? jobTitle;

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
    this.jobTitle,
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
         jobTitle: jobTitle
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
      jobTitle: user.jobTitle
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
