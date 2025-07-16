
// lib/features/shared/data/models/organization_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/organization.dart';

part 'organization_model.g.dart';

@JsonSerializable()
class OrganizationModel extends Organization {
  const OrganizationModel({
    required super.id,
    required super.code,
    required super.name,
    super.description,
    super.address,
    super.phone,
    super.email,
    super.logo,
    @JsonKey(name: 'primary_color') super.primaryColor,
    @JsonKey(name: 'secondary_color') super.secondaryColor,
    @JsonKey(name: 'is_active') required super.isActive,
    @JsonKey(name: 'created_at') required super.createdAt,
    @JsonKey(name: 'updated_at') required super.updatedAt,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) =>
      _$OrganizationModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrganizationModelToJson(this);

  factory OrganizationModel.fromEntity(Organization organization) {
    return OrganizationModel(
      id: organization.id,
      code: organization.code,
      name: organization.name,
      description: organization.description,
      address: organization.address,
      phone: organization.phone,
      email: organization.email,
      logo: organization.logo,
      primaryColor: organization.primaryColor,
      secondaryColor: organization.secondaryColor,
      isActive: organization.isActive,
      createdAt: organization.createdAt,
      updatedAt: organization.updatedAt,
    );
  }
}
