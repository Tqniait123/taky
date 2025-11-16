// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  email: json['email'] as String,
  passwordHash: json['passwordHash'] as String?,
  name: json['name'] as String,
  phone: json['phone'] as String?,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
  organizationId: json['organizationId'] as String,
  locale: json['locale'] as String?,
  profileImageUrl: json['profileImageUrl'] as String?,
  isActive: json['isActive'] as bool,
  isVerified: json['isVerified'] as bool,
  fcmToken: json['fcmToken'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  jobTitle: json['jobTitle'] as String?,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'passwordHash': instance.passwordHash,
  'name': instance.name,
  'phone': instance.phone,
  'role': _$UserRoleEnumMap[instance.role]!,
  'organizationId': instance.organizationId,
  'locale': instance.locale,
  'profileImageUrl': instance.profileImageUrl,
  'isActive': instance.isActive,
  'isVerified': instance.isVerified,
  'fcmToken': instance.fcmToken,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'jobTitle': instance.jobTitle,
};

const _$UserRoleEnumMap = {
  UserRole.admin: 'admin',
  UserRole.employee: 'employee',
  UserRole.officeBoy: 'officeBoy',
};
