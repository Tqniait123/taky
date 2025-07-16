
// lib/features/shared/domain/entities/user.dart
import 'package:equatable/equatable.dart';

enum UserRole { admin, employee, officeBoy }

class User extends Equatable {
  final String id;
  final String email;
  final String? passwordHash;
  final String name;
  final String? phone;
  final UserRole role;
  final String organizationId;
  final String? locale;
  final String? profileImageUrl;
  final bool isActive;
  final bool isVerified;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
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
  });

  @override
  List<Object?> get props => [
        id,
        email,
        passwordHash,
        name,
        phone,
        role,
        organizationId,
        locale,
        profileImageUrl,
        isActive,
        isVerified,
        fcmToken,
        createdAt,
        updatedAt,
      ];
}
