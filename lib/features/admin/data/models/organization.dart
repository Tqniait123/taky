import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:taqy/core/theme/colors.dart';

class AdminOrganization {
  final String id;
  final String name;
  final String code;
  final String? logoUrl;
  final String primaryColor;
  final String secondaryColor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  AdminOrganization({
    required this.id,
    required this.name,
    required this.code,
    this.logoUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory AdminOrganization.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminOrganization(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      logoUrl: data['logoUrl'],
      primaryColor: data['primaryColor'] ?? AppColors.primary.value.toString(),
      secondaryColor:
          data['secondaryColor'] ?? AppColors.secondary.value.toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'code': code,
      'logoUrl': logoUrl,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'isActive': isActive,
    };
  }

  Color get primaryColorValue {
    try {
      String colorString = primaryColor;
      if (colorString.startsWith('#')) {
        colorString = colorString.substring(1);
      }

      if (colorString.length == 6 || colorString.length == 8) {
        return Color(int.parse('FF$colorString', radix: 16));
      }

      return Color(int.parse(colorString));
    } catch (e) {
      return AppColors.primary;
    }
  }

  Color get secondaryColorValue {
    try {
      String colorString = secondaryColor;
      if (colorString.startsWith('#')) {
        colorString = colorString.substring(1);
      }

      if (colorString.length == 6 || colorString.length == 8) {
        return Color(int.parse('FF$colorString', radix: 16));
      }

      return Color(int.parse(colorString));
    } catch (e) {
      return AppColors.secondary;
    }
  }
}
