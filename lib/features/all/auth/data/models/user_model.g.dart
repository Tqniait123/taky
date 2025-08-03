// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  email: json['email'] as String,
  passwordHash: json['password_hash'] as String?,
  name: json['name'] as String,
  phone: json['phone'] as String?,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
  organizationId: json['organization_id'] as String,
  locale: json['locale'] as String?,
  profileImageUrl: json['profile_image_url'] as String?,
  isActive: json['is_active'] as bool,
  isVerified: json['is_verified'] as bool,
  fcmToken: json['fcm_token'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'password_hash': instance.passwordHash,
  'name': instance.name,
  'phone': instance.phone,
  'role': _$UserRoleEnumMap[instance.role]!,
  'organization_id': instance.organizationId,
  'locale': instance.locale,
  'profile_image_url': instance.profileImageUrl,
  'is_active': instance.isActive,
  'is_verified': instance.isVerified,
  'fcm_token': instance.fcmToken,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$UserRoleEnumMap = {
  UserRole.admin: 'admin',
  UserRole.employee: 'employee',
  UserRole.officeBoy: 'officeBoy',
};
