import 'package:equatable/equatable.dart';

class Organization extends Equatable {
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

  const Organization({
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

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    description,
    address,
    phone,
    email,
    logo,
    primaryColor,
    secondaryColor,
    isActive,
    createdAt,
    updatedAt,
  ];
}
