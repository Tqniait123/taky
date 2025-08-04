// Alternative approach using @JsonSerializable with fields
import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/organization.dart';

part 'organization_model.g.dart';

@JsonSerializable()
class OrganizationModel {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String? address;
  final String? phone;
  final String? email;
  final String? logo;
  final String? primaryColor;
  final String? secondaryColor;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrganizationModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.address,
    this.phone,
    this.email,
    this.logo,
    this.primaryColor,
    this.secondaryColor,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) => _$OrganizationModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrganizationModelToJson(this);

  // Convert to entity
  Organization toEntity() {
    return Organization(
      id: id,
      code: code,
      name: name,
      description: description,
      address: address,
      phone: phone,
      email: email,
      logo: logo,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

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
