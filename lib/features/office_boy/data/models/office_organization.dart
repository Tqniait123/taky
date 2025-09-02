
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OfficeOrganization {
  final String id;
  final String name;
  final String code;
  final String? logoUrl;
  final String primaryColor;
  final String secondaryColor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  OfficeOrganization({
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

  factory OfficeOrganization.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OfficeOrganization(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      logoUrl: data['logoUrl'],
      primaryColor: data['primaryColor'] ?? '#2196F3',
      secondaryColor: data['secondaryColor'] ?? '#FFC107',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Color get primaryColorValue {
    try {
      String colorString = primaryColor;
      if (colorString.startsWith('#')) {
        colorString = colorString.substring(1);
      }
      if (colorString.length == 6) {
        return Color(int.parse('FF$colorString', radix: 16));
      }
      if (colorString.length == 8) {
        return Color(int.parse(colorString, radix: 16));
      }
      return Color(int.parse(colorString));
    } catch (e) {
      return Colors.blue;
    }
  }

  Color get secondaryColorValue {
    try {
      String colorString = secondaryColor;
      if (colorString.startsWith('#')) {
        colorString = colorString.substring(1);
      }
      if (colorString.length == 6) {
        return Color(int.parse('FF$colorString', radix: 16));
      }
      if (colorString.length == 8) {
        return Color(int.parse(colorString, radix: 16));
      }
      return Color(int.parse(colorString));
    } catch (e) {
      return Colors.amber;
    }
  }
}
